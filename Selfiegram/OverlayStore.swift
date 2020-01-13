import Foundation
import UIKit

final class OverlayManager {
    static let shared = OverlayManager()
    typealias OverlayList = [OverlayInformation]
    private var overlayInfo : OverlayList
    
    static let downloadURLBase = URL(string: "https://raw.githubusercontent.com/" +
        "thesecretlab/learning-swift-3rd-ed/master/Data/")
    static let overlayListURL = URL(string: "overlays.json", relativeTo: OverlayManager.downloadURLBase)
    
    static var cacheDirectoryURL : URL {
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            fatalError("Cache directory not found! This should not happen!")
        }
        return cacheDirectory
    }
    static var cachedOverlayListURL : URL {
        return cacheDirectoryURL.appendingPathComponent("overlays.json", isDirectory: false)
    }
    
    init() {
        do {
            let overlayListData = try Data(contentsOf: OverlayManager .cachedOverlayListURL)
            self.overlayInfo = try JSONDecoder().decode(OverlayList.self, from: overlayListData)
        } catch {
            self.overlayInfo = []
        }
    }
    
    func urlForAsset(nameed assetName: String) -> URL? {
        return URL(string: assetName, relativeTo: OverlayManager .downloadURLBase)
    }
    
    func cachedURLForAsset(named assetName: String) -> URL? {
        return URL(string: assetName, relativeTo: OverlayManager .cacheDirectoryURL)
    }
    
    func availableOverlays() -> [Overlay] {
        return overlayInfo.compactMap { Overlay(info: $0) }
    }
    
    func refreshOverlays(completion: @escaping (OverlayList?, Error?) -> Void) {
        URLSession.shared.dataTask(with: OverlayManager.overlayListURL!) { (data, response, error) in
            if let error = error {
                NSLog("Failed to download \(String(describing: OverlayManager.overlayListURL)): \(error)")
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, OverlayManagerError.noDataLoaded)
                return
            }
            
            do {
                try data.write(to: OverlayManager.cachedOverlayListURL)
            } catch let error {
                NSLog("Failed to write data to \(OverlayManager.cachedOverlayListURL); reason: \(error)")
                completion(nil, error)
            }
            
            do {
                let overlayList = try JSONDecoder().decode(OverlayList.self, from: data)
                self.overlayInfo = overlayList
                completion(self.overlayInfo, nil)
                return
            } catch let decodeError {
                completion(nil, OverlayManagerError.cannotParseData(uderlyingError: decodeError))
            }
        }.resume()
    }
    
    private let loadingDispatchGroup = DispatchGroup()
    
    func loadOverlayAssets(refresh : Bool = false, completion: @escaping () -> Void) {
        if (refresh) {
            self.refreshOverlays(completion: { (overlays, error) in
                self.loadOverlayAssets(refresh:  false, completion: completion)
            })
            return
        }
        
        for info in overlayInfo {
            let names = [info.icon, info.leftImage, info.rightImage]
            
            typealias TaskURL = (source: URL, destination: URL)
            
            let taskURLs : [TaskURL] = names.compactMap {
                guard let sourceURL = URL(string: $0, relativeTo: OverlayManager.downloadURLBase)
                    else {
                        return nil
                }
                
                guard let destinationURL = URL(string: $0, relativeTo: OverlayManager.cacheDirectoryURL)
                    else {
                        return nil
                }
                
                return (source: sourceURL, destination: destinationURL)
            }
            
            for taskURL in taskURLs {
                loadingDispatchGroup.enter()
                
                URLSession.shared.dataTask(with: taskURL.source, completionHandler: { (data, response, error) in
                    defer {
                        self.loadingDispatchGroup.leave()
                    }
                    
                    guard let data = data else {
                        NSLog("Failed to download \(taskURL.source): \(error!)")
                        return
                    }
                    
                    do {
                        try data.write(to: taskURL.destination)
                    } catch let error {
                        NSLog("Failed to write to \(taskURL.destination): \(error)")
                    }
                }).resume()
            }
        }
        
        // Wait for all downloads to finish and then run the completion block
        loadingDispatchGroup.notify(queue: .main) {
            completion()
        }
    }
}

struct OverlayInformation : Codable {
    let icon: String
    let leftImage: String
    let rightImage: String
}

enum OverlayManagerError : Error {
    case noDataLoaded
    case cannotParseData(uderlyingError: Error)
}

struct Overlay {
    let previewIcon: UIImage
    let leftImage: UIImage
    let rightImage: UIImage
    
    init?(info: OverlayInformation) {
        guard
            let previewURL = OverlayManager.shared.cachedURLForAsset(named: info.icon),
            let leftURL = OverlayManager.shared.cachedURLForAsset(named: info.leftImage),
            let rightURL = OverlayManager.shared.cachedURLForAsset(named: info.rightImage)
            else {
                return nil
        }
        
        guard
            let previewImage = UIImage(contentsOfFile: previewURL.path),
            let leftImage = UIImage(contentsOfFile: leftURL.path),
            let rightImage = UIImage(contentsOfFile: rightURL.path)
            else {
                return nil
        }
        
        self.previewIcon = previewImage
        self.leftImage = leftImage
        self.rightImage = rightImage
    }
}
