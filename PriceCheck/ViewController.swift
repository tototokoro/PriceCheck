import UIKit

class ViewController: UIViewController {
    
    let bookData = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func toBookListView(_ sender: Any) {
        performSegue(withIdentifier: "showBookListView", sender: nil)
    }
    
    @IBAction func toCameraView(_ sender: Any) {
        performSegue(withIdentifier: "showCameraView", sender: nil)
    }
    
    @IBAction func toRegisterLibraryView(_ sender: Any) {
        performSegue(withIdentifier: "showRegisterWay", sender: nil)
    }
}
