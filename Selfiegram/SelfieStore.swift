import Foundation
import UIKit.UIImage

class Selfie : Codable
{
    let created : Date
    let id : UUID
    
    var title = "New Selfie!"
    
    var image : UIImage?
    {
        get
        {
            let selfieImage = try? SelfieStore.shared.getImage(id: self.id)
            return selfieImage
        }
        set
        {
            try? SelfieStore.shared.setImage(id: self.id, image: newValue)
        }
    }
    
    init(title: String) {
        self.title = title
        self.created = Date()
        self.id = UUID()
    }
}

enum SelfieStoreError : Error
{
    case cannotSaveImage(UIImage?)
}

final class SelfieStore
{
    static let shared = SelfieStore()
    
    func getImage(id: UUID) throws -> UIImage?
    {
        return nil
    }
    
    func setImage(id: UUID, image: UIImage?) throws
    {
        throw SelfieStoreError.cannotSaveImage(image)
    }
    
    func listSelfies() throws -> [Selfie]
    {
        return []
    }
    
    func delete(selfie: Selfie) throws
    {
        throw SelfieStoreError.cannotSaveImage(nil)
    }
    
    func delete(id: UUID) throws
    {
        throw SelfieStoreError.cannotSaveImage(nil)
    }
    
    func load(id: UUID) -> Selfie?
    {
        return nil
    }
    
    func save(selfie: Selfie) throws
    {
        throw SelfieStoreError.cannotSaveImage(nil)
    }
}
