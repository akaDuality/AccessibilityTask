//
//  StudentsViewController.swift
//  AccessibilityTask
//
//  Created by Mikhail Rubanov on 23.02.2021.
//

import UIKit

struct Student {
    let name: String
    let storyboardName: String
}

class StudentsViewController: UITableViewController {

    var students = [Student(name: "Default", storyboardName: "Main")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Студенты"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return students.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let student = students[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        
        var config = cell.defaultContentConfiguration()
        config.text = student.name
        
        cell.contentConfiguration = config

        return cell
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let student = students[indexPath.row]
        
        let controller = UIStoryboard(name: student.storyboardName, bundle: nil).instantiateInitialViewController()!
        
        if let navigationController = navigationController {
            navigationController.pushViewController(controller, animated: true)
        } else {
            present(controller, animated: true)
        }
    }
}
