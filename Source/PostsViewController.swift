//
//  PostsViewController.swift
//  edX
//
//  Created by Tang, Jeff on 5/19/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit



public struct DiscussionPostItem {

    public let title: String
    public let body: String
    public let author: String
    public let authorLabel : AuthorLabelType?
    public let createdAt: NSDate
    public let count: Int
    public let threadID: String
    public let following: Bool
    public let flagged: Bool
    public let pinned : Bool
    public var voted: Bool
    public var voteCount: Int
    public var type : PostThreadType
    public var read = false
    public let unreadCommentCount : Int
    
    // Unfortunately there's no way to make the default constructor public
    public init(
        title: String,
        body: String,
        author: String,
        authorLabel: AuthorLabelType?,
        createdAt: NSDate,
        count: Int,
        threadID: String,
        following: Bool,
        flagged: Bool,
        pinned: Bool,
        voted: Bool,
        voteCount: Int,
        type : PostThreadType,
        read : Bool,
        unreadCommentCount : Int
        ) {
            self.title = title
            self.body = body
            self.author = author
            self.authorLabel = authorLabel
            self.createdAt = createdAt
            self.count = count
            self.threadID = threadID
            self.following = following
            self.flagged = flagged
            self.pinned = pinned
            self.voted = voted
            self.voteCount = voteCount
            self.type = type
            self.read = read
            self.unreadCommentCount = unreadCommentCount
    }
    
    var hasByText : Bool {
        return following || pinned
    }

}

class PostsViewControllerEnvironment: NSObject {
    weak var router: OEXRouter?
    let networkManager : NetworkManager?
    let styles : OEXStyles
    
    init(networkManager : NetworkManager?, router: OEXRouter?, styles : OEXStyles = OEXStyles.sharedStyles()) {
        self.networkManager = networkManager
        self.router = router
        self.styles = styles
    }
}

class PostsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private enum Context {
        case Topic(DiscussionTopic)
        case Search(String)
        
        var allowsPosting : Bool {
            switch self {
            case Topic: return true
            case Search: return false
            }
        }
        
        var topic : DiscussionTopic? {
            switch self {
            case let Topic(topic): return topic
            case let Search(query): return nil
            }
        }
    }

    
    let environment: PostsViewControllerEnvironment
    
    private let identifierTitleAndByCell = "TitleAndByCell"
    private let identifierTitleOnlyCell = "TitleOnlyCell"
    
    private var tableView: UITableView!
    private var viewSeparator: UIView!
    private let loadController : LoadStateViewController
    
    private let refineLabel = UILabel()
    private let headerButtonHolderView = UIView()
    private let filterButton = UIButton.buttonWithType(.System) as! UIButton
    private let sortButton = UIButton.buttonWithType(.System) as! UIButton
    private let newPostButton = UIButton.buttonWithType(.System) as! UIButton
    private let courseID: String
    
    private let contentView = UIView()
    
    private let context : Context
    
    private var posts: [DiscussionPostItem] = []
    private var selectedFilter: DiscussionPostsFilter = .AllPosts
    private var selectedOrderBy: DiscussionPostsSort = .RecentActivity
    
    private var queryString : String?
    private var refineTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .XSmall, color: OEXStyles.sharedStyles().neutralDark())
    }

    private var filterTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size: .XSmall, color: self.environment.styles.primaryBaseColor())
    }
    
    init(environment: PostsViewControllerEnvironment, courseID: String, topic : DiscussionTopic) {
        self.environment = environment
        self.courseID = courseID
        self.context = Context.Topic(topic)
        loadController = LoadStateViewController(styles: environment.styles)
        super.init(nibName: nil, bundle: nil)
    }
    
    init(environment: PostsViewControllerEnvironment, courseID: String, queryString : String) {
        self.environment = environment
        self.courseID = courseID
        self.context = Context.Search(queryString)
        loadController = LoadStateViewController(styles: environment.styles)
        super.init(nibName: nil, bundle: nil)
        loadController.setupInController(self, contentView: contentView)
    }
    
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = self.environment.styles.standardBackgroundColor()
        
        view.addSubview(contentView)
        
        contentView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(view)
        }
        
        view.addSubview(refineLabel)
        view.addSubview(headerButtonHolderView)

        headerButtonHolderView.addSubview(filterButton)
        headerButtonHolderView.addSubview(sortButton)
        
        self.refineLabel.attributedText = self.refineTextStyle.attributedStringWithText(OEXLocalizedString("REFINE", nil))

        refineLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(view).offset(20)
            make.top.equalTo(view).offset(10)
            make.height.equalTo(20)
        }
        
        headerButtonHolderView.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(refineLabel.snp_trailing)
            make.trailing.equalTo(view)
            make.height.equalTo(40)
            make.top.equalTo(view)
        }
        
        
        
        var buttonTitle = NSAttributedString.joinInNaturalLayout(
            [Icon.Filter.attributedTextWithStyle(filterTextStyle.withSize(.XSmall)),
                filterTextStyle.attributedStringWithText(self.titleForFilter(self.selectedFilter))])
        filterButton.setAttributedTitle(buttonTitle, forState: .Normal)
        
        
        filterButton.snp_makeConstraints{ (make) -> Void in
            make.leading.equalTo(headerButtonHolderView)
            make.top.equalTo(headerButtonHolderView).offset(10)
            make.height.equalTo(context.allowsPosting ? 20 : 0)
            make.trailing.equalTo(sortButton.snp_leading)
        }
        
        buttonTitle = NSAttributedString.joinInNaturalLayout([Icon.Recent.attributedTextWithStyle(filterTextStyle.withSize(.XSmall)),
            filterTextStyle.attributedStringWithText(OEXLocalizedString("RECENT_ACTIVITY", nil))])
        sortButton.setAttributedTitle(buttonTitle, forState: .Normal)
        contentView.addSubview(sortButton)
        
        sortButton.snp_makeConstraints{ (make) -> Void in
            make.trailing.equalTo(headerButtonHolderView).offset(-20)
            make.top.equalTo(headerButtonHolderView).offset(10)
            make.height.equalTo(context.allowsPosting ? 20 : 0)
            make.width.equalTo(filterButton.snp_width)
        }
        
        newPostButton.backgroundColor = self.environment.styles.primaryXDarkColor()
        
        let style = OEXTextStyle(weight : .Normal, size: .Small, color: self.environment.styles.neutralWhite())
        buttonTitle = NSAttributedString.joinInNaturalLayout([Icon.Create.attributedTextWithStyle(style.withSize(.XSmall)),
            style.attributedStringWithText(OEXLocalizedString("CREATE_A_NEW_POST", nil))])
        newPostButton.setAttributedTitle(buttonTitle, forState: .Normal)
        
        newPostButton.contentVerticalAlignment = .Center
        
        contentView.addSubview(newPostButton)
        newPostButton.snp_makeConstraints{ (make) -> Void in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.height.equalTo(context.allowsPosting ? OEXStyles.sharedStyles().standardFooterHeight : 0)
            make.bottom.equalTo(contentView.snp_bottom)
        }
        
        tableView = UITableView(frame: contentView.bounds, style: .Plain)
        if let theTableView = tableView {
            theTableView.registerClass(PostTitleByTableViewCell.classForCoder(), forCellReuseIdentifier: identifierTitleAndByCell)
            theTableView.registerClass(PostTitleTableViewCell.classForCoder(), forCellReuseIdentifier: identifierTitleOnlyCell)
            theTableView.dataSource = self
            theTableView.delegate = self
            theTableView.tableFooterView = UIView(frame: CGRectZero)
            contentView.addSubview(theTableView)
        }
        
        if context.allowsPosting {
            tableView.snp_makeConstraints { (make) -> Void in
                make.leading.equalTo(view)
                make.top.equalTo(filterButton).offset(30)
                make.trailing.equalTo(view)
                make.bottom.equalTo(newPostButton.snp_top)
            }
            
            viewSeparator = UIView()
            viewSeparator.backgroundColor = self.environment.styles.neutralXLight()
            contentView.addSubview(viewSeparator)
            viewSeparator.snp_makeConstraints{ (make) -> Void in
                make.leading.equalTo(view)
                make.trailing.equalTo(view)
                make.height.equalTo(OEXStyles.dividerSize())
                make.top.equalTo(filterButton.snp_bottom).offset(context.allowsPosting ? 12 : 0)
            }
        }
        else {
            tableView.snp_makeConstraints { (make) -> Void in
                make.leading.equalTo(view)
                make.top.equalTo(view)
                make.trailing.equalTo(view)
                make.bottom.equalTo(newPostButton.snp_top)
            }
        }
        
        if let topic = context.topic {
            filterButton.oex_addAction(
                {[weak self] _ in
                    self?.showFilterPickerWithTopic(topic)
                }, forEvents: .TouchUpInside)
            sortButton.oex_addAction(
                {[weak self] _ in
                    self?.showSortPickerWithTopic(topic)
                }, forEvents: .TouchUpInside)
            newPostButton.oex_addAction(
                {[weak self] _ in
                    if let owner = self {
                        owner.environment.router?.showDiscussionNewPostFromController(owner, courseID: owner.courseID, initialTopic: topic)
                    }
            }, forEvents: .TouchUpInside)
            self.navigationItem.title = topic.name
        }
        else {
            self.navigationItem.title = OEXLocalizedString("SEARCH_RESULTS", nil)
        }
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
        loadController.setupInController(self, contentView: contentView)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.indexPathForSelectedRow().map { tableView.deselectRowAtIndexPath($0, animated: false) }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        switch context {
        case let .Topic(topic):
            loadPostsForTopic(topic, filter: selectedFilter, orderBy: selectedOrderBy)
        case let .Search(query):
            searchThreads(query)
        }
        
    }
    
    private func searchThreads(query : String) {
        self.posts.removeAll(keepCapacity: true)
        
        let apiRequest = DiscussionAPI.searchThreads(courseID: self.courseID, searchText: query)
        
        environment.networkManager?.taskForRequest(apiRequest) {[weak self] result in
            if let threads: [DiscussionThread] = result.data, owner = self {
                
                for discussionThread in threads {
                    if let item = owner.postItem(fromDiscussionThread : discussionThread) {
                        owner.posts.append(item)
                    }
                }
                if owner.posts.count == 0 {
                    var emptyResultSetMessage : NSString = OEXLocalizedString("EMPTY_RESULTSET", nil)
                    emptyResultSetMessage = emptyResultSetMessage.oex_formatWithParameters(["query_string" : query])
                    owner.loadController.state = LoadState.empty(icon: nil, message: emptyResultSetMessage as? String, attributedMessage: nil, accessibilityMessage: nil)
                }
                else {
                    owner.loadController.state = .Loaded
                }
                
                owner.tableView.reloadData()
            }
        }
    }

    private func postItem(fromDiscussionThread thread: DiscussionThread) -> DiscussionPostItem? {
        if let rawBody = thread.rawBody,
            let author = thread.author,
            let createdAt = thread.createdAt,
            let title = thread.title,
            let threadID = thread.identifier {
                return DiscussionPostItem(
                    title: title,
                    body: rawBody,
                    author: author,
                    authorLabel: thread.authorLabel,
                    createdAt: createdAt,
                    count: thread.commentCount,
                    threadID: threadID,
                    following: thread.following,
                    flagged: thread.flagged,
                    pinned: thread.pinned,
                    voted: thread.voted,
                    voteCount: thread.voteCount,
                    type : thread.type ?? .Discussion,
                    read : thread.read,
                    unreadCommentCount : thread.unreadCommentCount)
        }
        return nil
    }
    
    private func loadPostsForTopic(topic : DiscussionTopic, filter: DiscussionPostsFilter, orderBy: DiscussionPostsSort) {
        if let topic = context.topic, topicID = topic.id {
            let apiRequest = DiscussionAPI.getThreads(courseID: courseID, topicID: topicID, filter: filter, orderBy: orderBy)
            environment.networkManager?.taskForRequest(apiRequest) { [weak self] result in
                if let threads: [DiscussionThread] = result.data {
                    self?.posts.removeAll(keepCapacity: true)
                    
                    for discussionThread in threads {
                        if let item = self?.postItem(fromDiscussionThread: discussionThread) {
                            self?.posts.append(item)                        }
                    }
                }
                self?.loadController.state = .Loaded
                self?.tableView.reloadData()
                
            }
        }
    }
    
    func titleForFilter(filter : DiscussionPostsFilter) -> String {
        switch filter {
        case .AllPosts: return OEXLocalizedString("ALL_POSTS", nil)
        case .Unread: return OEXLocalizedString("UNREAD", nil)
        case .Unanswered: return OEXLocalizedString("UNANSWERED", nil)
        }
    }
    
    func titleForSort(filter : DiscussionPostsSort) -> String {
        switch filter {
        case .RecentActivity: return OEXLocalizedString("RECENT_ACTIVITY", nil)
        case .LastActivityAt: return OEXLocalizedString("MOST_ACTIVITY", nil)
        case .VoteCount: return OEXLocalizedString("MOST_VOTES", nil)
        }
    }
    
    
    func showFilterPickerWithTopic(topic : DiscussionTopic) {
        let options = [.AllPosts, .Unread, .Unanswered].map {
            return (title : self.titleForFilter($0), value : $0)
        }

        let controller = PSTAlertController.actionSheetWithItems(options, currentSelection : self.selectedFilter) {filter in
            self.selectedFilter = filter
            self.loadPostsForTopic(topic, filter: self.selectedFilter, orderBy: self.selectedOrderBy)
            
            let buttonTitle = NSAttributedString.joinInNaturalLayout([Icon.Filter.attributedTextWithStyle(self.filterTextStyle.withSize(.XSmall)),
                self.filterTextStyle.attributedStringWithText(self.titleForFilter(filter))])
            
            self.filterButton.setAttributedTitle(buttonTitle, forState: .Normal)
        }
        controller.addAction(PSTAlertAction(title: OEXLocalizedString("CANCEL", nil), style: .Cancel) { _ in
            })
        
        controller.showWithSender(nil, controller: self, animated: true, completion: nil)
    }
    
    func showSortPickerWithTopic(topic: DiscussionTopic) {
        let options = [.RecentActivity, .LastActivityAt, .VoteCount].map {
            return (title : self.titleForSort($0), value : $0)
        }
        
        let controller = PSTAlertController.actionSheetWithItems(options, currentSelection : self.selectedOrderBy) {sort in
            self.selectedOrderBy = sort
            self.loadPostsForTopic(topic, filter: self.selectedFilter, orderBy: self.selectedOrderBy)
            let buttonTitle = NSAttributedString.joinInNaturalLayout([Icon.Sort.attributedTextWithStyle(self.filterTextStyle.withSize(.XSmall)),
                self.filterTextStyle.attributedStringWithText(self.titleForSort(sort))])
            
            self.sortButton.setAttributedTitle(buttonTitle, forState: .Normal)
        }
        
        controller.addAction(PSTAlertAction(title: OEXLocalizedString("CANCEL", nil), style: .Cancel) { _ in
            })
        
        controller.showWithSender(nil, controller: self, animated: true, completion: nil)
    }
    
    // MARK - tableview delegate methods
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return posts[indexPath.row].hasByText ? 75 : 50
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    var cellTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size: .Base, color: self.environment.styles.primaryBaseColor())
    }
    
    var unreadIconTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Base, color: self.environment.styles.primaryBaseColor())
    }
    
    var readIconTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size: .Base, color: self.environment.styles.neutralBase())
    }
    
    func styledCellTextWithIcon(icon : Icon, text : String?) -> NSAttributedString? {
        let style = cellTextStyle.withSize(.Small)
        return text.map {text in
            return NSAttributedString.joinInNaturalLayout([icon.attributedTextWithStyle(style),
                style.attributedStringWithText(text)])
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(identifierTitleAndByCell, forIndexPath: indexPath) as! PostTitleByTableViewCell
            cell.usePost(posts[indexPath.row])
            return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        environment.router?.showDiscussionResponsesFromViewController(self, courseID : courseID, item: posts[indexPath.row])
    }
}



