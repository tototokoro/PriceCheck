import UIKit

class ResultViewController: UIViewController {
    
    var productList: [(name:String, price:String, shippingPrice:String, condition:String, link:URL, image:URL)] = []
    
    @IBOutlet weak var number: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print(productList)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
