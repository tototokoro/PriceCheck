import UIKit

class BookListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let bookData = UserDefaults.standard
    var BookList: [String] = []
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if bookData.object(forKey: "BookList") != nil{
            BookList += bookData.object(forKey: "BookList") as! [String]
            print(BookList)
        }
        
        tableView.dataSource = self
        tableView.delegate = self
        
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //セルの個数を指定
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BookList.count
    }
    
    //セルに値を設定するデータソースメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //セルを取得
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell") as! SavedProductTableViewCell
        
        //セルに値を設定
        cell.productImage.image = UIImage(named: "ISBN")
        cell.productNameLabel.text = BookList[indexPath.row]
        cell.previousPriceLabel.text = "1010"
        cell.currentPriceLabel.text = "110"
        return cell
    }
    
}
