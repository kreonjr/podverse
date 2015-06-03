//
//  PodcastsTableViewController.swift
//  
//
//  Created by Mitchell Downey on 6/2/15.
//
//

import UIKit
import CoreData

class PodcastsTableViewController: UITableViewController {
    
    var moc: NSManagedObjectContext!
    var podcastArray = [Podcast]()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext {
            moc = context
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "persistentStoreDidChange", name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "persistentStoreWillChange:", name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object: moc.persistentStoreCoordinator)
        
        loadData()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Podverse"
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: moc.persistentStoreCoordinator)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object: moc.persistentStoreCoordinator)
    }
    
    func persistentStoreDidChange() {
        // reenable UI and fetch data
//        self.navigationItem.title = "iCloud ready"
        self.navigationItem.leftBarButtonItem?.enabled = true
        
        loadData()
    }
    
    func persistentStoreWillChange(notification: NSNotification) {
        self.navigationItem.title = "Changes in progress"
        
        // disable the UI
        self.navigationItem.leftBarButtonItem?.enabled = false
        
        moc.performBlock { () -> Void in
            if self.moc.hasChanges {
                var error: NSError? = nil
                self.moc.save(&error)
                if error != nil {
                    println("Save error: \(error)")
                } else {
                    // drop any managed object references
                    self.moc.reset()
                }
            }
            
        }
    }

    @IBAction func addPodcast(sender: UIButton) {
        let addPodcastAlert = UIAlertController(title: "New Notebook", message: "Enter notebook title", preferredStyle: UIAlertControllerStyle.Alert)
        addPodcastAlert.addTextFieldWithConfigurationHandler(nil)
        addPodcastAlert.addAction(UIAlertAction(title: "Save Notebook", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction!) -> Void in
            let textField = addPodcastAlert.textFields?.last as! UITextField
            if textField.text != "" {
                let podcast = CoreDataHelper.insertManagedObject(NSStringFromClass(Podcast), managedObjectContext: self.moc) as! Podcast
                podcast.title = textField.text
                self.moc.save(nil)
                
                self.loadData()
            }
        }))
        
        addPodcastAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(addPodcastAlert, animated: true, completion: nil)
        
    }
    
    func loadData() {
        podcastArray = [Podcast]()
        podcastArray = CoreDataHelper.fetchEntities(NSStringFromClass(Podcast), managedObjectContext: moc, predicate: nil) as! [Podcast]
        
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return podcastArray.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell

        cell.textLabel?.text = podcastArray[indexPath.row].title

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showEpisodes" {
            let episodesTableViewController = segue.destinationViewController as! EpisodesTableViewController
            
            if let index = self.tableView.indexPathForSelectedRow() {
                episodesTableViewController.selectedPodcast = podcastArray[index.row]
            }
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
            
        }
    }

}
