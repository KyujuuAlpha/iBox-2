
//
//  FileSelectionViewController.swift
//  iBox
//
//  Created by Alsey Coleman Miller on 11/1/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import Swift
import UIKit
import BochsKit
import MBProgressHUD

private let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL

class FileSelectionViewController: UITableViewController {
    
    // MARK: - Properties
    
    var drive: Drive?
    
    // MARK: - Private Properties
    
    private var files = [String]()
    
    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refresh(self)
    }
    
    // MARK: - Actions
    
    @IBAction func refresh(sender: AnyObject) {
        var URLs:[NSURL] = []
        do{
            URLs = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(documentsURL, includingPropertiesForKeys: nil, options: [NSDirectoryEnumerationOptions.SkipsHiddenFiles,NSDirectoryEnumerationOptions.SkipsPackageDescendants,NSDirectoryEnumerationOptions.SkipsSubdirectoryDescendants] as NSDirectoryEnumerationOptions) as [NSURL]
        }catch{
        }
        var fileNames = [String]()
        
        for url in URLs {
            
            fileNames.append(url.lastPathComponent!)
        }
        
        self.files = fileNames
        
        self.tableView.reloadData()
    }
    
    @IBAction func createNewImage(sender: AnyObject) {
        
        // create alert controller
        let alertController = UIAlertController(title: NSLocalizedString("Create New HDD Image", comment: "Create New HDD Image Alert Controller Title"),
            message: NSLocalizedString("Specify a size (in MB) and a name", comment: "Create New HDD Image Alert Controller Message"),
            preferredStyle: UIAlertControllerStyle.Alert)
        
        // add text fields
        alertController.addTextFieldWithConfigurationHandler { (textField: UITextField!) -> Void in
            
            textField.text = "hddImage"
        }
        
        alertController.addTextFieldWithConfigurationHandler { (textField: UITextField!) -> Void in
            
            textField.text = "100"
        }
        
        // add create and cancel button
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction!) -> Void in
            
            alertController.dismissViewControllerAnimated(true, completion: nil)
        }))
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Create", comment: "Create"), style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) -> Void in
            
            // TODO: should probably validate file name (e.g. no spaces or invalid characters) and size text
            
            // dismiss alert controller and show progress view
            alertController.dismissViewControllerAnimated(true, completion: nil)
            
            let progressHUD = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            self.tableView.userInteractionEnabled = false
            
            // configure HUD
            progressHUD.labelText = NSLocalizedString("Creating image...", comment: "'Creating image...' Progress HUD text")
            
            // create image...
            
            let textField = alertController.textFields!.first //as UITextField
            
            let fileName = textField!.text! + ".img"
            
            let fileURL = documentsURL.URLByAppendingPathComponent(fileName)
            
            let size = Int((alertController.textFields![1] as UITextField).text!)!
            
            BXImage.createImageWithURL(fileURL, sizeInMB: UInt(size), completion: { (success: Bool) -> Void in
                
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    
                    if !success {
                        
                        // hide progress HUD and show alert view
                        MBProgressHUD.hideHUDForView(self.view, animated: true)
                        
                        self.tableView.userInteractionEnabled = true
                        
                        let alertView = UIAlertController(title: NSLocalizedString("Error", comment: "Error"),
                            message: NSLocalizedString("Could not create the image", comment: "Could not create the image"),
                            preferredStyle: UIAlertControllerStyle.Alert)
                        
                        alertView.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction!) -> Void in
                            
                            alertView.dismissViewControllerAnimated(true, completion: nil)
                        }))
                        
                        return
                    }
                    
                    // highlight file name row for existing file if the file already exists...
                    
                    if (self.files as NSArray).containsObject(fileName) {
                        
                        let existingRowIndex = (self.files as NSArray).indexOfObject(fileURL!)
                        
                        let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: existingRowIndex, inSection: 0))
                        
                        cell?.setSelected(true, animated: true)
                    }
                    // add file name to table with animation if doesn't already exist...
                    else {
                        
                        self.files.append(fileName)
                        self.files = (self.files as NSArray).sortedArrayUsingSelector("compare:") as!
                            [String]
                        let index = self.files.indexOf(fileName)!
                        self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                    }
                    
                    // save values
                    
                    self.drive!.fileName = fileName
                    
                    (self.drive as! HardDiskDrive).heads = 16
                    
                    (self.drive as! HardDiskDrive).sectorsPerTrack = 63
                    
                    (self.drive as! HardDiskDrive).cylinders = BXImage.numberOfCylindersForImageWithSizeInMB(UInt(size))
                    
                    // perform segue and hide HUD after delay (segue will modify entity)
                    
                    let delayInSeconds = 2
                    let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, (Int64(delayInSeconds) * Int64(NSEC_PER_SEC)))
                    
                    dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                        
                        self.tableView.userInteractionEnabled = true
                        
                        // hide progress HUD
                        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                        
                        // perform segue
                        self.performSegueWithIdentifier("unwindFromNewHDDImageSegue", sender: self)
                        
                        return
                    })
                })
                
            })
        }))
        
        // show
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.files.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellReusableIdentifier.FileNameCell.rawValue, forIndexPath: indexPath) as UITableViewCell
        
        // get model object
        let file = self.files[indexPath.row]
        
        // configure cell
        cell.textLabel!.text = (file as NSString).lastPathComponent
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        // get file
        let fileName = self.files[indexPath.row]
        
        let fileURL = documentsURL.URLByAppendingPathComponent(fileName)
        
        switch editingStyle {
            
        case .Delete:
            
            let error: NSError?
            do{
                try NSFileManager.defaultManager().removeItemAtURL(fileURL!)
            }catch{}
            /*
            if error != nil {
                
                let alertView = UIAlertController(title: NSLocalizedString("Error", comment: "Error"),
                    message: error!.localizedDescription,
                    preferredStyle: UIAlertControllerStyle.Alert)
                
                alertView.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction!) -> Void in
                    
                    alertView.dismissViewControllerAnimated(true, completion: nil)
                }))
                
                return
            }
            */
            // update table view data source
            self.files.removeAtIndex(indexPath.row)
            
            // remove table view cell row with animation
            tableView.beginUpdates()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            tableView.endUpdates()
            
        default:
            abort()
        }
    }
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "unwindFromFileSelectionSegue" {
            
            // save values...
            
            let cell = sender as! UITableViewCell
            
            self.drive?.fileName = self.files[self.tableView.indexPathForCell(cell)!.row]
        }
        
    }
}

// MARK: - Private Enumerations

private enum TableViewCellReusableIdentifier: String {
    
    case FileNameCell = "FileNameCell"
}
