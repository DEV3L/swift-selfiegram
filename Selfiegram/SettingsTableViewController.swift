import UIKit
import UserNotifications

class SettingsTableViewController: UITableViewController {
    private let notificationId = "SelfiegramReminder"
    
    @IBOutlet weak var locationSwitch: UISwitch!
    @IBOutlet weak var reminderSwitch: UISwitch!
    
    @IBAction func locationSwitchToggled(_ sender: Any) {
        UserDefaults.standard.set(locationSwitch.isOn, forKey: SettingsKey.saveLocation.rawValue)
    }
    
    @IBAction func reminderSwitchToggled(_ sender: Any) {
        let current = UNUserNotificationCenter.current()
        
        switch reminderSwitch.isOn
        {
        case true:
            let notificationOptions: UNAuthorizationOptions = [.alert]
            
            current.requestAuthorization(options: notificationOptions, completionHandler: { (granted, error) in
                if granted
                {
                    self.addNotificationRequest()
                }
                
                self.updateReminderSwitch()
            })
        case false:
            current.removeAllPendingNotificationRequests()
        }
    }
    
    override func viewDidLoad() {
        locationSwitch.isOn = UserDefaults.standard.bool(forKey: SettingsKey.saveLocation.rawValue)
        updateReminderSwitch()
        super.viewDidLoad()
    }
    
    func addNotificationRequest()
    {
        let current = UNUserNotificationCenter.current()
        current.removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = "Take a selfie!"
        var components = DateComponents()
        components.setValue(10, for: Calendar.Component.hour)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: self.notificationId, content: content, trigger: trigger)
        
        current.add(request, withCompletionHandler: { (error) in self.updateReminderSwitch() })
    }
    
    func updateReminderSwitch()
    {
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) in
            switch settings.authorizationStatus
            {
            case .authorized:
                UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { (requests) in
                    let active = requests.filter({ $0.identifier == self.notificationId}).count > 0
                    self.updateReminderUI(enabled: true, active: active)
                })
            case .denied:
                self.updateReminderUI(enabled: false, active: false)
            default:
                self.updateReminderUI(enabled: true, active: false)
            }
        })
    }
    
    func updateReminderUI(enabled: Bool, active: Bool)
    {
        OperationQueue.main.addOperation {
            self.reminderSwitch.isEnabled = enabled
            self.reminderSwitch.isOn = active
        }
    }
}

enum SettingsKey : String
{
    case saveLocation
}
