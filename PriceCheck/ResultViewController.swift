import UIKit
import SafariServices

class ResultViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SFSafariViewControllerDelegate {
    
    var passedData = [String: Any]()
    var productsList: [String: [ProductInfo]] = [:]
    var reserveURL = ""
    var isbn13: String?
    var bookList = [String: BookInfo]()
    var bookInfo = BookInfo()
    //ナビゲーションバーボタン（読みたい本）
    var addBookButton: UIBarButtonItem!
    //UserDefaultsのインスタンスを生成
    let bookData = UserDefaults.standard
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var reserveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        addBookButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(clickAddBook(sender:)))
        self.navigationItem.setRightBarButtonItems([addBookButton], animated: true)

        productsList = passedData["productsList"] as! [String : [ProductInfo]]
        isbn13 = productsList.keys.first
        
        if let tempData = bookData.data(forKey: "BookList"), let decoded = try? JSONDecoder().decode([String: BookInfo].self, from: tempData) {
            bookList = decoded
        }
        
        if let isbn13 = isbn13{
            bookInfo.image = passedData["image"] as? URL
            //要修正
            bookInfo.name = productsList[isbn13]?.first?.name
            
            if(!bookList.keys.contains(isbn13)){
                bookList[isbn13] = bookInfo
            }
            librarySearchBook(isbn13: isbn13)
        }
        
        self.tableView.reloadData()
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
        if let encoded = try? JSONEncoder().encode(bookList){
            bookData.set(encoded, forKey: "BookList")
            bookData.synchronize()
        }
        
        //ダイアログを表示する(To Do メッセージ部分工夫する)
        let alertController = UIAlertController(title: "リストに追加", message: "本をリストに追加しました", preferredStyle: .alert)
        //OKボタンを追加
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        //アクションを追加
        alertController.addAction(defaultAction)
        //ダイアログの表示
        present(alertController, animated: true, completion: nil)
    }

    //図書館の予約ページへ移動
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
        return (productsList[isbn13!]!.count)
//        return 1
    }
    
    //セルに値を設定するデータソースメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "productInfoCell", for: indexPath) as! CustomTableViewCell
        let product = productsList[isbn13!]![indexPath.row]

        if let imageData = try? Data(contentsOf: product.image!){
            cell.myImageView.image = UIImage(data: imageData)
        }
        cell.productNameLabel.text = product.name!.replacingOccurrences(of: " ", with: "")
        cell.conditionLabel.text = product.condition!.replacingOccurrences(of: " ", with: "")
        cell.priceLabel.text = "¥ \(String(product.price!))"
        cell.shippingPriceLabel.text = "¥ \(String(product.shippingPrice!))"
        
        return cell
    }
    
    //Cellが選択された時に呼び出されるdelegateメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //ハイライト解除
        tableView.deselectRow(at: indexPath, animated: true)
        
        //SFSafariViewを開く
        let safariViewController = SFSafariViewController(url: productsList[isbn13!]![indexPath.row].link!)
        
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
