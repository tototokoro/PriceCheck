import UIKit

class CitySelectViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var selectedPref: String = ""
    var pref_cityDict:[String: [String]] = [:]
    var tablePrefList:[String] = []
    let libraryData = UserDefaults.standard
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do{
            let csvPath = Bundle.main.path(forResource: "CityInfo", ofType: "csv")
            let csvData = try String(contentsOfFile: csvPath!)
            let allPrefList = csvData.components(separatedBy: "\n")
            
            for i in allPrefList{
                //["地方", "都道府県"]
                let pref_city = i.components(separatedBy: ",")
                //area_prefDictのキーにエリア名があるか確認
                if(!pref_cityDict.keys.contains(pref_city[0])){
                    pref_cityDict[pref_city[0]] = []
                }
                pref_cityDict[pref_city[0]]?.append(pref_city[1])
            }
            
        } catch {
            print(error)
        }
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (pref_cityDict[selectedPref]?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cityCell", for: indexPath)
        cell.textLabel?.text = pref_cityDict[selectedPref]?[indexPath.row]
        return cell
    }
    
    //市区町村登録
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        if let selected_city = self.pref_cityDict[self.selectedPref]?[indexPath.row] {
            if let pref_encode = selectedPref.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let city_cncode = selected_city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                
                guard let req_url = URL(string: "http://api.calil.jp/library?appkey=\(apiKey["kariru"]!)&pref=\(pref_encode)&city=\(city_cncode)&format=json&callback=&limit=1") else {
                    return
                }
                
                let req = URLRequest(url: req_url)
                
                let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
                
                let task = session.dataTask(with: req, completionHandler: {
                    (data, response, error) in
                    
                    session.finishTasksAndInvalidate()
                    do{
                        let decoder = JSONDecoder()
                        let libraries = try decoder.decode([Library].self, from: data!)
                        if let systemid = libraries.first?.systemid{
                            //ダイアログにて確認
                            let alertController: UIAlertController = UIAlertController(title: "図書館を登録", message: "\(selected_city)にある図書館を登録します。", preferredStyle: UIAlertControllerStyle.alert)
                            
                            //OKボタン
                            let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {
                                //ボタンが押された時の処理
                                (action: UIAlertAction!) -> Void in
                                print(systemid)
                                self.libraryData.set(systemid, forKey: "SystemID")
                                self.libraryData.synchronize()
                                
                                self.performSegue(withIdentifier: "showTopView", sender: nil)
                            })
                            
                            //キャンセルボタン
                            let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertActionStyle.cancel, handler:{
                                //ボタンが押された時の処理
                                (action: UIAlertAction!) -> Void in
                                print("キャンセル")
                            })
                            
                            alertController.addAction(defaultAction)
                            alertController.addAction(cancelAction)
                           
                            self.present(alertController, animated: true, completion: nil)
                        }
                    } catch {
                        print(error)
                    }
                })
                task.resume()
            }
        }
    }
}

struct Library: Codable {
    let systemid: String
}


