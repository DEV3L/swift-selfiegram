import UIKit
import CoreLocation

class SelfieListViewController:
    UITableViewController,
    UINavigationControllerDelegate,
    UIImagePickerControllerDelegate,
    CLLocationManagerDelegate
{
    let locationManager = CLLocationManager()
    
    var detailViewController: SelfieDetailViewController? = nil
    var lastLocation: CLLocation?
    
    var selfies : [Selfie] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do
        {
            selfies = try SelfieStore.shared.listSelfies()
                .sorted(by: { $0.created > $1.created })
        }
        catch let error
        {
            showError(message: "Failed to load slefies: \(error.localizedDescription)")
        }
        
        let addSelfieButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createNewSelfie))
        navigationItem.rightBarButtonItem = addSelfieButton
        
        if let split = splitViewController
        {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count - 1]
                as? UINavigationController)?.topViewController
                as? SelfieDetailViewController
        }
        
        self.locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }
    
    fileprivate func setLocation() {
        lastLocation = nil
        switch CLLocationManager.authorizationStatus() {
        case .denied, .restricted:
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            locationManager.requestLocation()
        }
    }
    
    @objc
    func createNewSelfie()
    {
        let shouldGetLocation = UserDefaults.standard.bool(forKey: SettingsKey.saveLocation.rawValue)
        if shouldGetLocation
        {
            setLocation()
        }
        
        let imagePicker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera)
        {
            imagePicker.sourceType = .camera
            if UIImagePickerController.isCameraDeviceAvailable(.front)
            {
                imagePicker.cameraDevice = .front
            }
            else if UIImagePickerController.isCameraDeviceAvailable(.rear)
            {
                imagePicker.cameraDevice = .rear
            }
        }
        else
        {
            imagePicker.sourceType = .photoLibrary
        }
        
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
        
    }
    
    func showError(message: String)
    {
        let alert = UIAlertController(title: "Error",
                                      message: message,
                                      preferredStyle: .alert)
        
        let action = UIAlertAction(title: "OK",
                                   style: .default, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    let timeIntervalFormatter : DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .spellOut
        formatter.maximumUnitCount = 1
        return formatter
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
    
    @objc
    func insertNewObject(_ sender: Any) {
        //        objects.insert(NSDate(), at: 0)
        //        let indexPath = IndexPath(row: 0, section: 0)
        //        tableView.insertRows(at: [indexPath], with: .automatic)
    }
    
    func newSelfieTaken(image: UIImage)
    {
        let newSelfie = Selfie(title: "New Selfie")
        newSelfie.image = image
        
        if let location = self.lastLocation
        {
            newSelfie.position = Selfie.Coordinate(location: location)
        }
        
        do
        {
            try SelfieStore.shared.save(selfie: newSelfie)
        }
        catch let error
        {
            showError(message: "Can't save photo: \(error)")
        }
        
        self.selfies.insert(newSelfie, at: 0)
        self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
    }
    
    // MARK: - Extensions
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            let message = "Couldn't get a picture from the image picker"
            showError(message: message)
            return
        }
        
        self.newSelfieTaken(image: image)
        self.dismiss(animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.lastLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        showError(message: error.localizedDescription)
    }
    
    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let selfie = selfies[indexPath.row]
                if let controller = (segue.destination as? UINavigationController)?
                    .topViewController as? SelfieDetailViewController
                {
                    controller.selfie = selfie
                    controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                    controller.navigationItem.leftItemsSupplementBackButton = true
                }
            }
        }
    }
    
    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selfies.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let selfie = selfies[indexPath.row]
        cell.textLabel?.text = selfie.title
        
        if let interval = timeIntervalFormatter.string(from: selfie.created, to: Date()) {
            cell.detailTextLabel?.text = "\(interval) ago"
        }
        else
        {
            cell.detailTextLabel?.text = nil
        }
        
        cell.imageView?.image = selfie.image
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let selfieToRemove = selfies[indexPath.row]
            do
            {
                try SelfieStore.shared.delete(selfie: selfieToRemove)
                selfies.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            catch
            {
                let title = selfieToRemove.title
                showError(message: "Failed to delete \(title)")
            }
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
}
