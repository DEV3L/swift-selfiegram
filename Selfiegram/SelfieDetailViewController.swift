import UIKit
import MapKit

class SelfieDetailViewController: UIViewController {
    @IBOutlet weak var selfieNameField: UITextField!
    @IBOutlet weak var dateCreatedLabel: UILabel!
    @IBOutlet weak var selfieImageView: UIImageView!
    @IBOutlet weak var mapView: MKMapView!
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        self.selfieNameField.resignFirstResponder()
        guard let selfie = selfie else
        {
            return
        }
        guard let text = selfieNameField?.text else
        {
            return
        }
        selfie.title = text
        try? SelfieStore.shared.save(selfie: selfie)
    }
    
    
    func configureView() {
        guard let selfie = selfie else
        {
            return
        }
        
        guard let selfieNameField = selfieNameField,
            let selfieImageView = selfieImageView,
            let dateCreatedLabel = dateCreatedLabel
            else
        {
            return
        }
        
        selfieNameField.text = selfie.title
        dateCreatedLabel.text = dateFormatter.string(from: selfie.created)
        selfieImageView.image = selfie.image
        
        if let position = selfie.position
        {
            self.mapView.setCenter(position.location.coordinate, animated: false)
            mapView.isHidden = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    var selfie: Selfie? {
        didSet {
            configureView()
        }
    }
    
    let dateFormatter = { () -> DateFormatter in
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()
}

