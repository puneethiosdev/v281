//
//  CourseFilterViewController.swift
//  edX
//
//  Created by Puneet JR on 10/02/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

protocol CourseFilterDelegate: class {
    func selectedCourseFilter(filterDict:[String:String])  //section:String, coursesTerm: String
 }

class CourseFilterViewController: UIViewController, UITableViewDataSource,UITableViewDelegate, UISearchBarDelegate{
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var viewingCoursesLbl: UILabel!
    @IBOutlet weak var verifiedCourses: UISwitch!
    
    var delegate:CourseFilterDelegate?
    var items = [[String : AnyObject]]()
    var sectionitems = [String]()
    var selectedIndexes = [NSIndexPath]()
    var activityIndicator = SpinnerView(size: SpinnerView.SpinSize.Large, color: SpinnerView.Color.Primary)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerNib(UINib(nibName: "CourseFilterCell", bundle: nil), forCellReuseIdentifier: "courseFilterCell")
        self.tableView.estimatedRowHeight = 280
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.allowsMultipleSelection = true
    
        activityIndicator.frame = CGRectMake(0.0, 0.0, 25.0, 25.0)
        activityIndicator.center = self.view.center
        view.addSubview(activityIndicator)
        activityIndicator.bringSubviewToFront(view)
        self.tableView.hidden = true
        activityIndicator.startAnimating()
        
        filterCoursesAPI()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Filter", style: .Plain, target: self, action: #selector(filterTapped))
    
        let selectFiltered = NSUserDefaults.standardUserDefaults().objectForKey("selectFiltered") as? NSData

        if((NSUserDefaults.standardUserDefaults().objectForKey("selectFiltered")) != nil) {
            let newArray = NSKeyedUnarchiver.unarchiveObjectWithData(selectFiltered!) as! [NSIndexPath]
            
            print (newArray.count)
            self.selectedIndexes = newArray
        }
    }
    
    
    func filterTapped() {
//        if self.selectedIndexes != nil {
            let defaults = NSUserDefaults.standardUserDefaults()
            let nsData = NSKeyedArchiver.archivedDataWithRootObject(self.selectedIndexes)
            defaults.setObject(nsData, forKey: "selectFiltered")
            defaults.synchronize()
//        }
        
        var filterDict = [String : String]()
        
        for (_, element) in self.selectedIndexes.enumerate() {
            let dictionary = self.items[element.section]["terms"] as? [String : AnyObject]
            let array1 =  Array(dictionary!.keys)
//            let someDict:[String:String] = [self.sectionitems[element.section]: array1[element.row]]
            filterDict.updateValue(array1[element.row], forKey: self.sectionitems[element.section])
        }
        
        if verifiedCourses.on {
            filterDict.updateValue("true", forKey: "verified")
        } else {
            filterDict.updateValue("false", forKey: "verified")
        }
        
        self.delegate?.selectedCourseFilter(filterDict)
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        print(self.sectionitems.count)
        return self.sectionitems.count
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sectionitems[section].capitalizedString
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let dictionary = self.items[section]["terms"] as? [String : AnyObject]
        print(Array(dictionary!.keys).count)
        return Array(dictionary!.keys).count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let identifier = "courseFilterCell"
        var cell: CourseFilterCell! = tableView.dequeueReusableCellWithIdentifier(identifier) as? CourseFilterCell

        if cell == nil {
            tableView.registerNib(UINib(nibName: "CourseFilterCell", bundle: nil), forCellReuseIdentifier: identifier)
            cell = tableView.dequeueReusableCellWithIdentifier(identifier) as? CourseFilterCell
        }
        
        let dictionary = self.items[indexPath.section]["terms"] as? [String : AnyObject]
        let array =  Array(dictionary!.keys)
        
        cell.nameLbl.text = array[indexPath.row]

        let path = NSIndexPath(forRow: array.indexOf(cell.nameLbl.text!)!, inSection: self.sectionitems.indexOf(self.sectionitems[indexPath.section])!)
        
        print(path)

        cell.isCellTag = indexPath
        cell.countlbl.text = String(dictionary![cell.nameLbl.text!]!)

        if self.selectedIndexes.contains(indexPath) {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }

        cell.selectionStyle = .None
        
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath){
        print(self.selectedIndexes.count)
        print("\n \n \n")
    }
  
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let currentIndex = self.selectedIndexes.indexOf(indexPath) {
            self.selectedIndexes.removeAtIndex(currentIndex)
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
        } else {
            if self.selectedIndexes.count > 0{
                for (index, element) in self.selectedIndexes.enumerate() {
                    if element.section == indexPath.section {
                        self.selectedIndexes.removeAtIndex(index)
                        self.tableView.reloadRowsAtIndexPaths([element], withRowAnimation: .None)
                    }
                }
                
                self.selectedIndexes.append(indexPath)
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
            } else {
                    self.selectedIndexes.append(indexPath)
                    self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
            }
        }
    }
    
    enum JSONError: String, ErrorType {
        case NoData = "ERROR: no data"
        case ConversionFailed = "ERROR: conversion from JSON failed"
    }
    
    func filterCoursesAPI() {
        let urlPath = kFILTER_COURSES+"?page_size=400"+"&mobile=true" //kFILTER_COURSES
        
        guard let url = NSURL(string: urlPath) else {
            print("Error creating endpoint")
            return
        }

        let request = NSMutableURLRequest(URL:url)
        
        NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            
            // parse the result as JSON, since that's what the API provided
            do {
                guard let json = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? NSDictionary else {
                    print("error trying to convert data to JSON")
                    return
                }
                // now we have the todo, let's just print it to prove we can access it
                print("The json is: " + json.description)

                let totalCount = json["total"] as? Int
                
                if let facets = json["facets"] as? NSDictionary {
                    for (key,value) in facets {
                        print("item \(key): \(value)")
                        
                        if key as! String != "verified" {
                            self.sectionitems.append(key as! String)
                            self.items.append(value as! [String : AnyObject])
                        }
                    }
                }
                
                print(self.sectionitems,self.items)
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.viewingCoursesLbl.text = String("Viewing  \(totalCount!) results")
                    //Stop Activity Indicator
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.removeFromSuperview()
                    
                    self.tableView.hidden = false

                    self.tableView.reloadData()
                })
            } catch  {
                print("error trying to convert data to JSON")
                return
            }
        }.resume()
    }
}
