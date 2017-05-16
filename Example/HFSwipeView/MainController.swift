//
//  MainController.swift
//  HFSwipeView
//
//  Created by DragonCherry on 8/19/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import TinyLog

extension UIView {
    public func setBorder(_ width: CGFloat, color: UIColor) {
        self.layer.borderWidth = width
        self.layer.borderColor = color.cgColor
    }
}

public enum TestSegue: String {
    
    case
    kSegueSimpleController                  = "kSegueSimpleController",
    kSegueSimpleCirculatingController       = "kSegueSimpleCirculatingController",
    kSegueMagnifyController                 = "kSegueMagnifyController",
    kSegueAutoSlideController               = "kSegueAutoSlideController",
    kSegueEdgePreviewController             = "kSegueEdgePreviewController"
    
    static let allValues: NSArray = [
        kSegueSimpleController.rawValue,
        kSegueSimpleCirculatingController.rawValue,
        kSegueMagnifyController.rawValue,
        kSegueAutoSlideController.rawValue,
        kSegueEdgePreviewController.rawValue
    ]
}

class MainController: UIViewController {
    
    fileprivate let kTestCellMenuIdentifier = "kTestCellMenuIdentifier"
    fileprivate var tableView: UITableView!
    
    let menuItems: NSArray = TestSegue.allValues
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView = UITableView(frame: view.frame)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
    }
    
    func titleForIndexPath(_ indexPath: IndexPath) -> String {
        var title: String!
        switch indexPath.row {
        case 0:
            title = "Simple Example"
        case 1:
            title = "Circulating"
        case 2:
            title = "Magnifying"
        case 3:
            title = "Auto Slide"
        case 4:
            title = "Edge Preview"
        default:
            title = ""
        }
        return title
    }
}

extension MainController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let segue: String = menuItems.object(at: indexPath.row) as! String
        log("tableView - didSelectRowAtIndexPath: \(indexPath.row), segue: \(segue)")
        self.performSegue(withIdentifier: segue, sender: self)
    }
}

extension MainController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dequeuedCell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: kTestCellMenuIdentifier)
        var cell: UITableViewCell? = nil
        if let dequeuedCell = dequeuedCell {
            cell = dequeuedCell
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: kTestCellMenuIdentifier)
            cell!.selectionStyle = .none
        }
        cell?.textLabel!.text = titleForIndexPath(indexPath)
        return cell!
    }
}
