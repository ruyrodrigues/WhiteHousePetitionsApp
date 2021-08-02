import UIKit

class ViewController: UITableViewController {

    var petitions = [Petition]()
    var searchPetitions = [Petition]()
    var searching = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        performSelector(inBackground: #selector(fetchJSON), with: nil)
        
        let creditButton = UIBarButtonItem(title: "CREDITS", style: .plain, target: self, action: #selector(showCredits))
        let searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(search))
        let clearButton = UIBarButtonItem(title: "Clear filters", style: .plain, target: self, action: #selector(clear))
        
        navigationItem.rightBarButtonItems = [searchButton, clearButton]
        navigationItem.leftBarButtonItem = creditButton
        
    }
    
    @objc func fetchJSON() {
        let urlString: String

        if navigationController?.tabBarItem.tag == 0 {
            urlString = "https://api.whitehouse.gov/v1/petitions.json?limit=100"
        } else {
            urlString = "https://api.whitehouse.gov/v1/petitions.json?signatureCountFloor=10000&limit=100"
        }

        if let url = URL(string: urlString) {
            if let data = try? Data(contentsOf: url) {
                parse(json: data)
                return
            }
        }

        performSelector(onMainThread: #selector(showError), with: nil, waitUntilDone: false)
    }
    
    //MARK: - Methods
    
    @objc func clear() {
        searching = false
        tableView.reloadData()
    }
    
    @objc func search() {
        let ac = UIAlertController(title: "Search Petitions", message: nil, preferredStyle: .alert)
        ac.addTextField()
        let searchAction = UIAlertAction(title: "Submit", style: .default) {
            [weak self, weak ac] _ in
            guard let searchText = ac?.textFields?[0].text else { return }
            self?.add(searchText)
        }
        ac.addAction(searchAction)
        present(ac, animated: true)
    }
    
    func add(_ text: String) {
        searchPetitions.removeAll()
        if text.count != 0 {
            searching = true
            let lowerText = text.lowercased()
            for petition in petitions {
                if (petition.title.lowercased().contains(lowerText) || petition.body.lowercased().contains(lowerText)) {
                    searchPetitions.append(petition)
                }
            }
        } else {
            searching = false
        }
        tableView.reloadData()
      
    }
    
    
    @objc func showCredits() {
        let ac = UIAlertController(title: "Credits", message: "The contents of this app comes from the We The People API of the Whitehouse.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Continue", style: .default))
        present(ac, animated: true)
    }
    
    @objc func showError() {
        let ac = UIAlertController(title: "Loading error", message: "There was a problem loading the feed; please check your connection and try again.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    
    
    func parse(json: Data) {
        let decoder = JSONDecoder()

        if let jsonPetitions = try? decoder.decode(Petitions.self, from: json) {
            petitions = jsonPetitions.results
            tableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: false)
        } else {
            performSelector(onMainThread: #selector(showError), with: nil, waitUntilDone: false)
        }
    }
    
    //MARK: - Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searching {
            return searchPetitions.count
        } else {
            return petitions.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if searching {
            let searchPetition = searchPetitions[indexPath.row]
            cell.textLabel?.text = searchPetition.title
            cell.detailTextLabel?.text = searchPetition.body
        } else {
            let petition = petitions[indexPath.row]
            cell.textLabel?.text = petition.title
            cell.detailTextLabel?.text = petition.body
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewController = DetailViewController()
        viewController.detailItem = petitions[indexPath.row]
        viewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.hidesBarsOnSwipe = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.hidesBarsOnSwipe = false
    }
}

