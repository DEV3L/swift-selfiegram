import XCTest
import UIKit
import CoreLocation

@testable import Selfiegram

class SelfitStoreTests: XCTestCase {
    func createImage(text: String) -> UIImage
    {
        UIGraphicsBeginImageContext(CGSize(width: 100, height: 100))
        
        defer {
            UIGraphicsEndImageContext()
        }
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        label.font = UIFont.systemFont(ofSize: 50)
        label.text = text
        
        label.drawHierarchy(in: label.frame, afterScreenUpdates: true)
        
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
    
    func testCreateSelfie()
    {
        let selfieTitle = "Creation Test Selfie"
        let newSelfie = Selfie(title: selfieTitle)
        
        try? SelfieStore.shared.save(selfie: newSelfie)
        
        let allSelfies = try! SelfieStore.shared.listSelfies()
        
        guard allSelfies.first(where: {$0.id == newSelfie.id}) != nil else
        {
            XCTFail("Selfies list should contain the one we just created")
            return
        }
        
        XCTAssertEqual(selfieTitle, newSelfie.title)
    }
    
    func testSavingImage() throws
    {
        let newSelfie = Selfie(title: "Selfie with image test")
        
        newSelfie.image = createImage(text: "100")
        try SelfieStore.shared.save(selfie: newSelfie)
        
        let loadedImage = try SelfieStore.shared.getImage(id: newSelfie.id)
        
        XCTAssertNotNil(loadedImage, "The image should be loaded")
    }
    
    func testLoadingSelfie() throws
    {
        let selfieTitle = "Test loading selfie"
        let newSelfie = Selfie(title: selfieTitle)
        try SelfieStore.shared.save(selfie: newSelfie)
        let id = newSelfie.id
        
        let loadedSelfie = SelfieStore.shared.load(id: id)
        
        XCTAssertNotNil(loadedSelfie, "The selfie should be loaded")
        XCTAssertEqual(loadedSelfie?.id, newSelfie.id, "The loaded selfie should have the same ID")
        XCTAssertEqual(loadedSelfie?.created, newSelfie.created, "The loaded selfie should have the same creation date")
        XCTAssertEqual(loadedSelfie?.title, newSelfie.title, "The loaded selfie should have the same title")
    }
    
    func testDeletingSelfie() throws
    {
        let newSelfie = Selfie(title: "Test deleting a selfie")
        try SelfieStore.shared.save(selfie: newSelfie)
        let id = newSelfie.id
        
        let allSelfies = try SelfieStore.shared.listSelfies()
        try SelfieStore.shared.delete(id: id)
        let selfieList = try SelfieStore.shared.listSelfies()
        let loadedSelfie = SelfieStore.shared.load(id: id)
        
        XCTAssertEqual(allSelfies.count - 1, selfieList.count, "There should be one less selfie after deletion")
        XCTAssertNil(loadedSelfie, "Deleted selfie should be nil")              
    }
    
    func testLocationSelfie()
    {
        let location = CLLocation(latitude: -42.8819, longitude: 147.3238)
        
        let newSelfie = Selfie(title: "Location Selfie")
        let newImage = createImage(text: "LOCATION")
        newSelfie.image = newImage
        newSelfie.position = Selfie.Coordinate(location: location)
        
        do
        {
            try SelfieStore.shared.save(selfie: newSelfie)
        }
        catch
        {
            XCTFail("Failed to save the location selfie")
        }
        
        let loadedSelfie = SelfieStore.shared.load(id: newSelfie.id)
        
        XCTAssertNotNil(loadedSelfie?.position)
        XCTAssertEqual(newSelfie.position, loadedSelfie?.position)
    }
}
