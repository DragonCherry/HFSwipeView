//
//  MainController.swift
//  HFSwipeView
//
//  Created by DragonCherry on 8/19/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import HFUtility

extension UIView {
    public func setBorder(width: CGFloat, color: UIColor) {
        self.layer.borderWidth = width
        self.layer.borderColor = color.CGColor
    }
}

public enum TestSegue: String {
    
    case
    kSegueSimpleController = "kSegueSimpleController",
    kSegueSimpleCirculatingController = "kSegueSimpleCirculatingController",
    kSegueSyncController = "kSegueSyncController",
    kSegueMagnifyController = "kSegueMagnifyController"
    
    static let allValues: NSArray = [
        kSegueSimpleController.rawValue,
        kSegueSimpleCirculatingController.rawValue,
        kSegueSyncController.rawValue,
        kSegueMagnifyController.rawValue
    ]
}

class MainController: UIViewController {
    
    private let kTestCellMenuIdentifier = "kTestCellMenuIdentifier"
    private var tableView: UITableView?
    
    let menuItems: NSArray = TestSegue.allValues
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func loadView() {
        super.loadView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
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
        
        let title = menuItems.objectAtIndex(indexPath.row) as! String
        cell?.textLabel!.text = title
        
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let segue: String = menuItems.objectAtIndex(indexPath.row) as! String
        log("tableView - didSelectRowAtIndexPath: \(indexPath.row), segue: \(segue)")
        self.performSegueWithIdentifier(segue, sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        log("prepareForSegue - \(segue.identifier)")
    }
}