import UIKit

class ResultViewController: UIViewController {
    var codeNum: String?
    
    @IBOutlet weak var number: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        number.text = codeNum
        
        print("sss\(number)")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
