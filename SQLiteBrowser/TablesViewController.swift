import UIKit

class TablesViewController: UITableViewController {
    
    var url: URL? {
        didSet {
            guard let `url` = url else { return }
            
            self.openDatabase(url)
        }
    }
    
    var tableList: [String] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Tables"
        openLastDatabase()
    }
    
    func openLastDatabase() {
        if let dbUrl = UserDefaults.standard.url(forKey: "lastdb") {
            openDatabase(dbUrl)
        } else {
            if let dbTest = copyTestDatabase() {
                openDatabase(dbTest)
            }
        }
    }
    
    func copyTestDatabase() -> URL? {
        let filer = FileManager.default
        
        do {
            let docs = filer.urls(for: .documentDirectory, in: .userDomainMask).first!
            let target = docs.appendingPathComponent("Test.db")
            let source = Bundle.main.url(forResource: "Test", withExtension: "db")!
            print("Copying test database to \(target)...")
            try filer.copyItem(at: source, to: target)
            return target
        } catch {
            print("Error copying test database")
            print(error)
        }
        
        return nil
    }
    
    func openDatabase(_ name: URL) {
        Database.shared.open(file: name)
        
        if Database.shared.isConnected() {
            saveLastDatabase(name)
            tableList = Database.shared.getTables()
        } else {
            print("Error connecting to database")
            // Alert user
        }
    }
    
    func saveLastDatabase(_ name: URL) {
        UserDefaults.standard.set(name, forKey: "lastdb")
    }
}


extension TablesViewController  {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "TableCell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "TableCell")
        }
        cell?.textLabel?.text = tableList[indexPath.row]
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tableName = tableList[indexPath.row]
        
        let vc = BrowseViewController()
        vc.tableName = tableName
        self.navigationController?.pushViewController(vc, animated: true)
    }

}
