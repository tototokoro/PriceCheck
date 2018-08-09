import UIKit
import SafariServices

class ResultViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SFSafariViewControllerDelegate {
    
    var passedData: [String: Any] = [:]
    var productList: [(name:String, price:Int, shippingPrice:Int, condition:String, link:URL, image:URL)] = []
    var reserveURL = ""
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var reserveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        productList = passedData["products"] as! [(name: String, price: Int, shippingPrice: Int, condition: String, link: URL, image: URL)]
        reserveURL = passedData["reserveURL"] as! String
        
        tableView.dataSource = self
        
        tableView.delegate = self
        
        if(self.reserveURL != ""){
            self.reserveButton.isHidden = false
            self.reserveButton.isEnabled = true
            print(reserveURL)
        } else{
            print("その本ないよ")
        }
    }

    @IBAction func showReservePage(_ sender: Any) {
        let safariViewController = SFSafariViewController(url: URL(string: reserveURL)!)
        
        safariViewController.delegate = self
        
        present(safariViewController, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return productList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "productCell", for: indexPath) as! CustomTableViewCell
        
        if let imageData = try? Data(contentsOf: productList[indexPath.row].image){
            cell.myImageView.image = UIImage(data: imageData)
        }

        cell.productNameLabel.text = productList[indexPath.row].name.replacingOccurrences(of: " ", with: "")

        cell.conditionLabel.text = productList[indexPath.row].condition.replacingOccurrences(of: " ", with: "")
        cell.priceLabel.text = "¥ \(String(productList[indexPath.row].price))"

        cell.shippingPriceLabel.text = "¥ \(String(productList[indexPath.row].shippingPrice))"
        
        return cell
    }
    
    //Cellが選択された時に呼び出されるdelegateメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //ハイライト解除
        tableView.deselectRow(at: indexPath, animated: true)
        
        //SFSafariViewを開く
        let safariViewController = SFSafariViewController(url: productList[indexPath.row].link)
        
        //delegateの通知先を自分自身
        safariViewController.delegate = self
        
        //SafariViewが開かれる
        present(safariViewController, animated: true, completion: nil)
    }
    
    //SafariViewが閉じられた時に呼ばれるdelegateメソッド
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        //SafariViewを閉じる
        dismiss(animated: true, completion: nil)
    }
}
