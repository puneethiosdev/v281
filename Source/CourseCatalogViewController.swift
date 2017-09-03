//
//  CourseCatalogViewController.swift
//  edX
//
//  Created by Akiva Leffert on 11/30/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit
private let FilterViewFrame = CGRectMake(0, 0, 30, 30)
private let PageSize = 20
private let footerHeight = 30


class CourseCatalogViewController: UIViewController, CoursesTableViewControllerDelegate, NSURLSessionTaskDelegate,UISearchBarDelegate,NSURLSessionDelegate,CourseFilterDelegate {
    typealias Environment = protocol<NetworkManagerProvider, OEXRouterProvider, OEXSessionProvider, OEXConfigProvider, OEXAnalyticsProvider>
    
    private let environment : Environment
    private let tableController : CoursesTableViewController
    private let loadController = LoadStateViewController()
    private let insetsController = ContentInsetsController()
    private let searchBar = UISearchBar()
    private var loadmoreView = UIView();
    var filterCoursesCount : Int16 = 0
    var pageNumber : Int = 1
    var pageIndex : Int = 1
    
    init(environment : Environment) {
        self.environment = environment
        self.tableController = CoursesTableViewController(environment: environment, context: .CourseCatalog)
        super.init(nibName: nil, bundle: nil)
        self.navigationItem.title = Strings.findCourses
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
        
        //Right bar button
        filterRightBarButton()
        
    }
    
    func filterRightBarButton() {
        let allcoursesItem = UIBarButtonItem(image: UIImage(named: "filterIcon") , style:.Plain, target: nil, action: nil)
        allcoursesItem.oex_setAction {
            
            let courseFilterVC:CourseFilterViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("courseFilterVC") as! CourseFilterViewController
            
            courseFilterVC.delegate = self
            
            self.navigationController?.pushViewController(courseFilterVC, animated: true)

        }
        self.navigationItem.rightBarButtonItem = allcoursesItem
        
    }
    
    
    
    func selectedCourseFilter(filterDict: [String : String]) {
        
        self.loadController.state = .Initial
        data_requestMultiFilter(kFILTER_COURSES, hasLoadMore: false, paramDict: filterDict)
    }
    
//    func selectedCourseFilter(section: String, coursesTerm: String) {
//        
//        self.loadController.state = .Initial
//        data_request(kFILTER_COURSES+"?"+section+"="+coursesTerm,hasLoadMore: false)
//    }
    
    
//    func filterRightBarButton() {
//        let allcoursesItem = UIBarButtonItem(title: "View all courses", style:.Plain, target: nil, action: nil)
//        allcoursesItem.oex_setAction {
//            self.loadController.state = .Initial
//            self.searchBar.resignFirstResponder()
//            self.searchBar.text = nil
//            self.data_request(kFILTER_COURSES,hasLoadMore: false)
//        }
//        self.navigationItem.rightBarButtonItem = allcoursesItem
//    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var paginationController : PaginationController<OEXCourse> = {
        let username = self.environment.session.currentUser?.username ?? ""
        precondition(username != "", "Shouldn't be showing course catalog without a logged in user")
        let organizationCode =  self.environment.config.organizationCode()
        
        let paginator = WrappedPaginator(networkManager: self.environment.networkManager) { page in
            return CourseCatalogAPI.getCourseCatalog(username, page: 1)
//            return CourseCatalogAPI.getCourseCatalog(username, page: page, organizationCode: organizationCode)
        }
        return PaginationController(paginator: paginator, tableView: self.tableController.tableView)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.accessibilityIdentifier = "course-catalog-screen";
        
        //Initialize Course SearchBar
        searchBar.delegate = self
        searchBar.showsCancelButton = true
        self.view.addSubview(searchBar)
        searchBar.snp_makeConstraints{ make in
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.top.equalTo(self.view)
        }
        
        addChildViewController(tableController)
        tableController.didMoveToParentViewController(self)
        self.loadController.setupInController(self, contentView: tableController.view)
        
        self.view.addSubview(tableController.view)
        /*
         tableController.view.snp_makeConstraints {make in
         make.edges.equalTo(self.view)
         }
         */
        tableController.view.snp_makeConstraints {make in
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.top.equalTo(searchBar.snp_bottom)
            make.bottom.equalTo(self.view)
        }
        
        loadmoreView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: footerHeight))
        let activityIndicator = SpinnerView(size: .Large, color: .Primary)
        loadmoreView.addSubview(activityIndicator)
        activityIndicator.snp_makeConstraints { make in
            make.center.equalTo(loadmoreView)
        }
        loadmoreView.hidden = true
        self.view.addSubview(loadmoreView)
    
        self.view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        
        tableController.delegate = self
        
//        data_request(kFILTER_COURSES,hasLoadMore: false)
        data_request(kFILTER_COURSES+"?page_size=400"+"&page_index=1"+"&mobile=true", hasLoadMore: false)

        /*
         paginationController.stream.listen(self, success:
         {[weak self] courses in
         self?.loadController.state = .Loaded
         self?.tableController.courses = courses
         self?.tableController.tableView.reloadData()
         }, failure: {[weak self] error in
         self?.loadController.state = LoadState.failed(error)
         }
         )
         paginationController.loadMore()
         */
        insetsController.setupInController(self, scrollView: tableController.tableView)
        insetsController.addSource(
            // add a little padding to the bottom since we have a big space between
            // each course card
            ConstantInsetsSource(insets: UIEdgeInsets(top: 0, left: 0, bottom: StandardVerticalMargin, right: 0), affectsScrollIndicators: false)
        )
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        searchBar.resignFirstResponder()
    }
    //Hide, Display Load more option
    func showLoadMoreOption(){
        tableController.view.snp_updateConstraints {make in
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.top.equalTo(searchBar.snp_bottom)
            make.bottom.equalTo(self.view).offset(-30)
        }
        loadmoreView.hidden = false;
        loadmoreView.snp_updateConstraints{ make in
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.top.equalTo(tableController.view.snp_bottom)
            make.bottom.equalTo(self.view)
        }
        tableController.view.updateConstraints()
    }
    func hideLoadMoreOption(){
        tableController.view.snp_updateConstraints {make in
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.top.equalTo(searchBar.snp_bottom)
            make.bottom.equalTo(self.view)
        }
        loadmoreView.snp_updateConstraints{ make in
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.top.equalTo(tableController.view.snp_bottom)
            make.bottom.equalTo(self.view)
        }
        tableController.view.updateConstraints()
        tableController.view.setNeedsLayout()
        tableController.view.updateConstraintsIfNeeded()
        
        loadmoreView.updateConstraints()
        loadmoreView.setNeedsLayout()
        loadmoreView.updateConstraintsIfNeeded()
        
        loadmoreView.hidden = true;
        
        self.view.layoutIfNeeded()
    }
    
    //Parameter value url
    func data_requestMultiFilter(filterCourseURL : String, hasLoadMore : Bool, paramDict:[String: String])
    {
    
        let parameterString = paramDict.stringFromHttpParameters()
        let requestURL = String(UTF8String:"\(filterCourseURL)?\(parameterString)")!
        
        //Is it required to display load more option at bottom
        if hasLoadMore {
            showLoadMoreOption()
        }
        let escapedAddress : String = requestURL.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!
        
        let url:NSURL = NSURL(string: escapedAddress)!
        
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: nil)
        
        let dataTask = session.dataTaskWithRequest(NSURLRequest.init(URL: url), completionHandler: { (let data, let response, let error) in
            
            guard let _:NSData = data, let _:NSURLResponse = response  where error == nil else {
                print("error")
                return
            }
            do {
                let filterCoursesJson = JSON.init(data: data!, options: NSJSONReadingOptions(), error: nil)
                //                print(filterCoursesJson)
                let allEmails = filterCoursesJson["results"].array?.flatMap {item in
                    item.dictionaryObject.map { OEXCourse(dictionary: $0) }
                }
                
                let courses : [OEXCourse] = allEmails!
                self.filterCoursesCount = filterCoursesJson["total"].int16!
                
                dispatch_async(dispatch_get_main_queue()) {
                    if(courses.count == 0){
                        self.loadController.state = .Loaded
                        self.tableController.courses = courses
                        self.tableController.tableView.reloadData()
                        
                        if (self.searchBar.text == ""){
                            self.showOverlayMessage("We couldn't find any results for selected options.")
                        } else {
                            self.showOverlayMessage("We couldn't find any results for " + self.searchBar.text!+".")
                        }
                        self.searchBar.text = nil;
                        self.data_request(kFILTER_COURSES,hasLoadMore: false)
                    }else{
                        self.loadController.state = .Loaded
                        self.tableController.courses = courses
                        self.tableController.tableView.reloadData()
                    }
                    self.hideLoadMoreOption()
                }
            }
            
        })
        dataTask.resume()
    }
    
    //Request to get filter courses
    func data_request(filterCourseURL : String, hasLoadMore : Bool)
    {
        //Is it required to display load more option at bottom
        if hasLoadMore {
            showLoadMoreOption()
        }
        let escapedAddress : String = filterCourseURL.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!
        let url:NSURL = NSURL(string: escapedAddress)!
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: nil)
        let dataTask = session.dataTaskWithRequest(NSURLRequest.init(URL: url), completionHandler: { (let data, let response, let error) in
            
            guard let _:NSData = data, let _:NSURLResponse = response  where error == nil else {
                print("error")
                return
            }
            do {
                let filterCoursesJson = JSON.init(data: data!, options: NSJSONReadingOptions(), error: nil)
//                print(filterCoursesJson)
                let allEmails = filterCoursesJson["results"].array?.flatMap {item in
                    item.dictionaryObject.map { OEXCourse(dictionary: $0) }
                }

                let courses : [OEXCourse] = allEmails!
                self.filterCoursesCount = filterCoursesJson["total"].int16!
                
                dispatch_async(dispatch_get_main_queue()) {
                    if(courses.count == 0){
                        self.loadController.state = .Loaded
                        self.tableController.courses = courses
                        self.tableController.tableView.reloadData()
                        
                        self.showOverlayMessage("We couldn't find any results for " + self.searchBar.text!+".")
                        self.searchBar.text = nil;
                        self.data_request(kFILTER_COURSES,hasLoadMore: false)
                        
                    }else{
                        self.loadController.state = .Loaded
                        self.tableController.courses = courses
                        self.tableController.tableView.reloadData()
                    }
                    self.hideLoadMoreOption()
                }
            }
        })
        dataTask.resume()
    }
 
    // MARK: NSURLSessionDelegate methods
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void){
        
        let credential = NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!)
        completionHandler(.UseCredential, credential)
        
    }
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?){
        
    }
    
    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void){
        let credential = NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!)
        completionHandler(.UseCredential, credential)
        
    }
    // MARK: UISearchBarDelegate methods
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        return true
    }
    func searchBar(searchBar: UISearchBar, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        //For BackSpace
        if (text == "") {
            return true;
        }
        //Don't allow first letter as space
        if (range.location == 0) {
            let trimmedString = text.stringByTrimmingCharactersInSet(.whitespaceCharacterSet())
            if (trimmedString.characters.count == 0){
                return false;
            }else{
                return true;
            }
        }
        return true
    }
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        self.loadController.state = .Initial
        data_request(kFILTER_COURSES+"?search_string="+searchBar.text!,hasLoadMore: false)
        
    }
    func searchBarCancelButtonClicked(searchBar: UISearchBar){
        /*
         if (searchBar.text != nil && searchBar.text?.characters.count != 0) {
         searchBar.resignFirstResponder()
         searchBar.text = nil
         self.loadController.state = .Initial
         data_request("kFILTER_COURSES")
         }else{
         searchBar.resignFirstResponder()
         searchBar.text = nil
         }*/
        searchBar.resignFirstResponder()
        searchBar.text = nil
    }
    // MARK: CoursesTableViewControllerDelegate methods
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackScreenWithName(OEXAnalyticsScreenFindCourses)
    }
    
    func coursesTableChoseCourse(course: OEXCourse) {
        //kAMAT Changes
        guard let courseID = course.course_id_amat else {
            return
        }
        self.environment.router?.showCourseCatalogDetail(courseID, fromController:self)
    }
    func courseTableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath){
        if filterCoursesCount == 0 {
            
        }else{
            //print("Last row \(indexPath.row)")
            if filterCoursesCount-1 > indexPath.row {
                pageNumber += 1
                pageIndex += 1
                
                if (searchBar.text != nil && searchBar.text?.characters.count != 0) {
                    searchBar.resignFirstResponder()
                    //self.loadController.state = .Initial
                    data_request(kFILTER_COURSES+"?search_string="+searchBar.text!+"&page_size=\(pageNumber*PageSize)"+"&page_index=\(pageIndex)"+"&mobile=true",hasLoadMore: true)
//                    data_request(kFILTER_COURSES+"?search_string="+searchBar.text!+"&page_size=\(pageNumber*PageSize)"+"&page_index=1"+"&mobile=True",hasLoadMore: true)
                    
                }else{
                    searchBar.resignFirstResponder()
                    //self.loadController.state = .Initial
                    data_request(kFILTER_COURSES+"?page_size=\(pageNumber*PageSize)"+"&page_index=\(pageIndex)"+"&mobile=true",hasLoadMore: true)
//                    data_request(kFILTER_COURSES+"?page_size=\(pageNumber*PageSize)"+"&page_index=1"+"&mobile=True",hasLoadMore: true)
                }
            }
        }
    }
    
}

// Testing only

extension CourseCatalogViewController {
    
    var t_loaded : Stream<()> {
        return self.paginationController.stream.map {_ in
            return
        }
    }
    
}

extension String {
    
    /// Percent escapes values to be added to a URL query as specified in RFC 3986
    ///
    /// This percent-escapes all characters besides the alphanumeric character set and "-", ".", "_", and "~".
    ///
    /// http://www.ietf.org/rfc/rfc3986.txt
    ///
    /// :returns: Returns percent-escaped string.
    
    func stringByAddingPercentEncodingForURLQueryValue() -> String? {
        let allowedCharacters = NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        
        return self.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters)
    }
    
}



extension Dictionary {
    
    /// Build string representation of HTTP parameter dictionary of keys and objects
    ///
    /// This percent escapes in compliance with RFC 3986
    ///
    /// http://www.ietf.org/rfc/rfc3986.txt
    ///
    /// :returns: String representation in the form of key1=value1&key2=value2 where the keys and values are percent escaped
    
    func stringFromHttpParameters() -> String {
        let parameterArray = self.map { (key, value) -> String in
            let percentEscapedKey = (key as! String).stringByAddingPercentEncodingForURLQueryValue()!
            let percentEscapedValue = (value as! String).stringByAddingPercentEncodingForURLQueryValue()!
            return "\(percentEscapedKey)=\(percentEscapedValue)"
        }
        
        return parameterArray.joinWithSeparator("&")
    }
    
}
