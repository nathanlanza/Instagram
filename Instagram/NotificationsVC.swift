import UIKit
import CloudKit

class NotificationsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // CloudKit
    let manager = CloudManager.sharedManager
    var user: User!
    
    // shows a list of notifications
    @IBOutlet weak var tableView: UITableView!
    
    var likesAndComments = [RecordToClassProtocol]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getLikesAndComments()
        
        // set badge to # of objects in data array
        self.updateTabBadge("\(likesAndComments.count)")
        
        setUpUI()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        getLikesAndComments()
    }
    
    func getLikesAndComments() {
        CloudManager.sharedManager.getLikesForUser(CloudManager.sharedManager.currentUser) { (likes, error) -> () in
            if let error = error {
                print(error)
            }
            guard let likes = likes else { return }
            for like in likes {
                self.likesAndComments.append(like)
            }
            NSOperationQueue.mainQueue().addOperationWithBlock{ () -> Void in
                self.tableView.reloadData()
            }
        }
        CloudManager.sharedManager.getCommentsForUser(CloudManager.sharedManager.currentUser) { (comments, error) -> () in
            if let error = error {
                print(error)
            }
            guard let comments = comments else { return }
            for comment in comments {
                self.likesAndComments.append(comment)
            }
            NSOperationQueue.mainQueue().addOperationWithBlock{ () -> Void in
                self.tableView.reloadData()
            }
        }
    }
    
    
    
    //MARK: - Table view delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let likeOrComment = likesAndComments[indexPath.row]
        let postReference = likeOrComment.record.objectForKey("Post") as! CKReference
        let postRecord = postReference.recordID
        
        CloudManager.sharedManager.publicDatabase.fetchRecordWithID(postRecord) { (record, error) -> Void in
            if let error = error {
                print(error)
            }
            guard let record = record else { return }
            let post = Post(fromRecord: record)
            
            NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let feedVC = storyboard.instantiateViewControllerWithIdentifier("FeedVC") as! FeedVC
                feedVC.singlePost = post
                self.navigationController?.pushViewController(feedVC, animated: true)
            }
        }
    }
    
    
    // MARK: - Table view data source
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")! as UITableViewCell
        
        let likeOrComment = likesAndComments[indexPath.row]
        var text = ""
        if let like = likeOrComment as? Like {
            text = "\(like.likerAlias) liked your post"
        } else if let comment = likeOrComment as? Comment {
            text = "\(comment.commenterAlias) commented on your post"
        }
        cell.textLabel?.text = text
        
        //cell.imageView?.image = UIImage(named: "user")
        
        cell.textLabel?.numberOfLines = 0
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return likesAndComments.count
    }
    
    func updateTabBadge(value: String) {
        
        (tabBarController!.tabBar.items![3]).badgeValue = value
    }
    
}
