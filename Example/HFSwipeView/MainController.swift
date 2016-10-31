//
//  MainController.swift
//  HFSwipeView
//
//  Created by DragonCherry on 8/19/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit

extension UIView {
    public func setBorder(width: CGFloat, color: UIColor) {
        self.layer.borderWidth = width
        self.layer.borderColor = color.CGColor
    }
}

public enum TestSegue: String {
    
    case
    kSegueSimpleController                  = "kSegueSimpleController",
    kSegueSimpleCirculatingController       = "kSegueSimpleCirculatingController",
    kSegueSyncController                    = "kSegueSyncController",
    kSegueMagnifyController                 = "kSegueMagnifyController",
    kSegueAutoSlideController               = "kSegueAutoSlideController",
    kSegueEdgePreviewController             = "kSegueEdgePreviewController"
    
    static let allValues: NSArray = [
        kSegueSimpleController.rawValue,
        kSegueSimpleCirculatingController.rawValue,
        kSegueSyncController.rawValue,
        kSegueMagnifyController.rawValue,
        kSegueAutoSlideController.rawValue,
        kSegueEdgePreviewController.rawValue
    ]
}

class MainController: UIViewController {
    
    private let kTestCellMenuIdentifier = "kTestCellMenuIdentifier"
    private var tableView: UITableView!
    
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

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print("prepareForSegue - \(segue.identifier)")
    }
    
    func titleForIndexPath(indexPath: NSIndexPath) -> String {
        var title: String!
        switch indexPath.row {
        case 0:
            title = "Simple Example"
        case 1:
            title = "Circulating"
        case 2:
            title = "Sync"
        case 3:
            title = "Magnifying"
        case 4:
            title = "Auto Slide"
        case 5:
            title = "Edge Preview"
        default:
            title = ""
        }
        return title
    }
}

extension MainController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let segue: String = menuItems.objectAtIndex(indexPath.row) as! String
        print("tableView - didSelectRowAtIndexPath: \(indexPath.row), segue: \(segue)")
        self.performSegueWithIdentifier(segue, sender: self)
    }
}

extension MainController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let dequeuedCell: UITableViewCell? = tableView.dequeueReusableCellWithIdentifier(kTestCellMenuIdentifier)
        var cell: UITableViewCell? = nil
        if let dequeuedCell = dequeuedCell {
            cell = dequeuedCell
        } else {
            cell = UITableViewCell(style: .Default, reuseIdentifier: kTestCellMenuIdentifier)
            cell!.selectionStyle = .None
        }
        cell?.textLabel!.text = titleForIndexPath(indexPath)
        return cell!
    }
}