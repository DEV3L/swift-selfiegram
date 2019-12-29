import UIKit

class SelfieDetailViewController: UIViewController {
    @IBOutlet weak var selfieNameField: UITextField!
    @IBOutlet weak var dateCreatedLabel: UILabel!
    @IBOutlet weak var selfieImageView: UIImageView!
    
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

