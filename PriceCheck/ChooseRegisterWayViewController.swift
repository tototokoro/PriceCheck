import UIKit

class ChooseRegisterWayViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func showAreaTable(_ sender: Any) {
        performSegue(withIdentifier: "showAreaView", sender: nil)
    }
    
}
