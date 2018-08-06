import UIKit

class ResultViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var productList: [(name:String, price:String, shippingPrice:String, condition:String, link:URL, image:URL)] = []
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
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
        cell.priceLabel.text = productList[indexPath.row].price

        cell.shippingPriceLabel.text = productList[indexPath.row].shippingPrice
        
        print("s")
        return cell
    }
}
