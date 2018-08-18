import UIKit

class AreaSelectViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var areaList:[String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            let csvPath = Bundle.main.path(forResource: "AreaList", ofType: "csv")
            let csvData = try String(contentsOfFile: csvPath!)
            
            areaList = csvData.components(separatedBy: "\n")
            
        } catch {
            print(error)
        }
        
        tableView.dataSource = self
        tableView.delegate = self

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //セルの数を返す
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return areaList.count
    }
    
    //セルに値を設定する
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "areaCell", for: indexPath)
        cell.textLabel?.text = areaList[indexPath.row]
        return cell
    }
    
    //セルが選択された時
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showPrefSelectView", sender: areaList[indexPath.row])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPrefSelectView" {
            let nextViewController = segue.destination as! PrefSelectViewController
            nextViewController.selectedArea = sender as! String
        }
    }
    
}
