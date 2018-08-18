import UIKit

class PrefSelectViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var selectedArea: String = ""
    var area_prefDict:[String: [String]] = [:]
    var tablePrefList:[String] = []
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do{
            let csvPath = Bundle.main.path(forResource: "AreaPref", ofType: "csv")
            let csvData = try String(contentsOfFile: csvPath!)
            let allPrefList = csvData.components(separatedBy: "\n")
            
            for i in allPrefList{
                //["地方", "都道府県"]
                let area_pref = i.components(separatedBy: ",")
                //area_prefDictのキーにエリア名があるか確認
                if(!area_prefDict.keys.contains(area_pref[0])){
                    area_prefDict[area_pref[0]] = []
                }
                area_prefDict[area_pref[0]]?.append(area_pref[1])
            }
            
        } catch {
            print(error)
        }
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.reloadData()
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (area_prefDict[selectedArea]?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "prefCell", for: indexPath)
        cell.textLabel?.text = area_prefDict[selectedArea]?[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showCitySelectView", sender: area_prefDict[selectedArea]?[indexPath.row])
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCitySelectView" {
            let nextViewController = segue.destination as! CitySelectViewController
            nextViewController.selectedPref = sender as! String
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
