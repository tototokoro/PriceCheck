import UIKit

class BookListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let bookData = UserDefaults.standard
    var bookList = [String: BookInfo]()
    
    struct Objects {
        var isbn13 : String!
        var sectionObjects : BookInfo!
    }
    
    var objectArray = [Objects]()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
       
        if let tempData = bookData.data(forKey: "BookList"), let decoded = try? JSONDecoder().decode([String: BookInfo].self, from: tempData) {
            bookList = decoded
        }
        
        for (key, value) in bookList {
            objectArray.append(Objects(isbn13: key, sectionObjects: value))
        }
        
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //セルの個数を指定
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookList.count
    }
    
    //セルに値を設定するデータソースメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //セルを取得
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell") as! SavedProductTableViewCell
        
        //セルに値を設定
        if let imageData = try? Data(contentsOf: objectArray[indexPath.row].sectionObjects.image!){
            cell.productImage.image = UIImage(data: imageData)
        }
        cell.productNameLabel.text = objectArray[indexPath.row].sectionObjects.name
        return cell
    }
    
    //各セルの編集（削除）をするメソッド セルの削除ボタンのデザイン変更
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteButton: UITableViewRowAction = UITableViewRowAction(style: .normal, title: "削除"){ (action, index) -> Void in
            self.bookList[self.objectArray[indexPath.row].isbn13] = nil
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            if let encoded = try? JSONEncoder().encode(self.bookList){
                self.bookData.set(encoded, forKey: "BookList")
                self.bookData.synchronize()
            }
        }
        deleteButton.backgroundColor = UIColor.red
        
        return [deleteButton]
    }
    
}
