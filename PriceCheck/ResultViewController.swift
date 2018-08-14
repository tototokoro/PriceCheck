import UIKit
import SafariServices

class ResultViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SFSafariViewControllerDelegate {
    
    var passedData: [String: Any] = [:]
    var productList: [(name:String, price:Int, shippingPrice:Int, condition:String, link:URL, image:URL)] = []
    var reserveURL = ""
    var isbn13: String?
    var bookList: [String] = []
    //ナビゲーションバーボタン（読みたい本）
    var addBookButton: UIBarButtonItem!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var reserveButton: UIButton!
    
    //UserDefaultsのインスタンスを生成
    let bookData = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBookButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(clickAddBook(sender:)))

        self.navigationItem.setRightBarButtonItems([addBookButton], animated: true)

        //前画面から受け取ったデータを各変数に代入
        productList = passedData["products"] as! [(name: String, price: Int, shippingPrice: Int, condition: String, link: URL, image: URL)]
        isbn13 = passedData["isbn13"] as? String
        
        if let tempData = bookData.object(forKey: "BookList") {
            bookList = tempData as! [String]
        }
        
        tableView.dataSource = self
        tableView.delegate = self
        
        self.tableView.reloadData()
        
        if let isbn13 = isbn13{
            if(!bookList.contains(isbn13)){
                bookList.append(isbn13)
            }
            
            librarySearchBook(isbn13: isbn13)
        }
    }
    
    //図書館に本があるか探す
    func librarySearchBook(isbn13: String){
        let system_id = "Tokyo_Nakano"
        
        guard let req_url = URL(string: "http://api.calil.jp/check?appkey=\(apiKey["kariru"]!)&isbn=\(isbn13)&systemid=\(system_id)&callback=no&format=json") else {
            return
        }
        
        //リクエストに必要な情報を生成
        let req = URLRequest(url: req_url)
        
        //データ転送を管理するためのセッションを生成
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        
        //リクエストをタスクとして登録
        let task = session.dataTask(with: req, completionHandler: {
            (data, response, error) in
            //セッションを終了
            session.finishTasksAndInvalidate()
            do{
                if let jsonObject = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary,
                    let books = jsonObject["books"] as? NSDictionary,
                    let isbn = books[isbn13] as? NSDictionary,
                    //要修正
                    let location = isbn[system_id] as? NSDictionary
                {
                    
                    DispatchQueue.global(qos: .default).async {
                        self.reserveURL = (location["reserveurl"] as? String)!
                        
                        DispatchQueue.main.async {
                            if(self.reserveURL != ""){
                                self.reserveButton.isHidden = false
                                self.reserveButton.isEnabled = true
                                
                                self.reserveButton.setTitle("図書館で予約する", for: .normal)
                            } else{
                                self.reserveButton.setTitle("見つかりませんでした", for: .normal)
                            }
                        }
                    }
                }
            } catch {
                print(error)
            }
        })
        task.resume()
    }
    
    //本をリストに追加
    @objc func clickAddBook(sender: UIButton){
        bookData.set(bookList, forKey: "BookList")
        
        //ダイアログを表示する(To Do メッセージ部分工夫する)
        let alertController = UIAlertController(title: "リストに追加", message: "本をリストに追加しました", preferredStyle: .alert)
        //OKボタンを追加
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        //アクションを追加
        alertController.addAction(defaultAction)
        
        //ダイアログの表示
        present(alertController, animated: true, completion: nil)
        
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
    
    //セルの個数を指定
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return productList.count
    }
    
    //セルに値を設定するデータソースメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "productInfoCell", for: indexPath) as! CustomTableViewCell
        
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
