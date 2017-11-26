
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

private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as URL

class FileSelectionViewController: UITableViewController {
    
    // MARK: - Properties
    
    var drive: Drive?
    
    // MARK: - Private Properties
    
    fileprivate var files = [String]()
    
    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refresh(self)
    }
    
    // MARK: - Actions
    
    @IBAction func refresh(_ sender: AnyObject) {
        var URLs:[URL] = []
        do{
            URLs = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: [FileManager.DirectoryEnumerationOptions.skipsHiddenFiles,FileManager.DirectoryEnumerationOptions.skipsPackageDescendants,FileManager.DirectoryEnumerationOptions.skipsSubdirectoryDescendants] as FileManager.DirectoryEnumerationOptions) as [URL]
        }catch{
        }
        var fileNames = [String]()
        
        for url in URLs {
            
            fileNames.append(url.lastPathComponent)
        }
        
        self.files = fileNames
        
        self.tableView.reloadData()
    }
    
    @IBAction func createNewImage(_ sender: AnyObject) {
        
        // create alert controller
        let alertController = UIAlertController(title: NSLocalizedString("Create New HDD Image", comment: "Create New HDD Image Alert Controller Title"),
            message: NSLocalizedString("Specify a size (in MB) and a name", comment: "Create New HDD Image Alert Controller Message"),
            preferredStyle: UIAlertControllerStyle.alert)
        
        // add text fields
        alertController.addTextField { (textField: UITextField!) -> Void in
            
            textField.text = "hddImage"
        }
        
        alertController.addTextField { (textField: UITextField!) -> Void in
            
            textField.text = "100"
        }
        
        // add create and cancel button
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertActionStyle.cancel, handler: { (action: UIAlertAction!) -> Void in
            
            alertController.dismiss(animated: true, completion: nil)
        }))
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Create", comment: "Create"), style: UIAlertActionStyle.default, handler: { (action: UIAlertAction!) -> Void in
            
            // TODO: should probably validate file name (e.g. no spaces or invalid characters) and size text
            
            // dismiss alert controller and show progress view
            alertController.dismiss(animated: true, completion: nil)
            
            let progressHUD = MBProgressHUD.showAdded(to: self.view, animated: true)
            self.tableView.isUserInteractionEnabled = false
            
            // configure HUD
            progressHUD?.labelText = NSLocalizedString("Creating image...", comment: "'Creating image...' Progress HUD text")
            
            // create image...
            
            let textField = alertController.textFields!.first //as UITextField
            
            let fileName = textField!.text! + ".img"
            
            let fileURL = documentsURL.appendingPathComponent(fileName)
            
            let size = Int((alertController.textFields![1] as UITextField).text!)!
            
            BXImage.createImage(with: fileURL, sizeInMB: UInt(size), completion: { (success: Bool) -> Void in
                
                OperationQueue.main.addOperation({ () -> Void in
                    
                    if !success {
                        
                        // hide progress HUD and show alert view
                        MBProgressHUD.hide(for: self.view, animated: true)
                        
                        self.tableView.isUserInteractionEnabled = true
                        
                        let alertView = UIAlertController(title: NSLocalizedString("Error", comment: "Error"),
                            message: NSLocalizedString("Could not create the image", comment: "Could not create the image"),
                            preferredStyle: UIAlertControllerStyle.alert)
                        
                        alertView.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertActionStyle.cancel, handler: { (action: UIAlertAction!) -> Void in
                            
                            alertView.dismiss(animated: true, completion: nil)
                        }))
                        
                        return
                    }
                    
                    // highlight file name row for existing file if the file already exists...
                    
                    if (self.files as NSArray).contains(fileName) {
                        
                        let existingRowIndex = (self.files as NSArray).index(of: fileURL)
                        
                        let cell = self.tableView.cellForRow(at: IndexPath(row: existingRowIndex, section: 0))
                        
                        cell?.setSelected(true, animated: true)
                    }
                    // add file name to table with animation if doesn't already exist...
                    else {
                        
                        self.files.append(fileName)
                        self.files = (self.files as NSArray).sortedArray(using: #selector(NSNumber.compare(_:))) as!
                            [String]
                        let index = self.files.index(of: fileName)!
                        self.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: UITableViewRowAnimation.automatic)
                    }
                    
                    // save values
                    
                    self.drive!.fileName = fileName
                    
                    (self.drive as! HardDiskDrive).heads = 16
                    
                    (self.drive as! HardDiskDrive).sectorsPerTrack = 63
                    
                    (self.drive as! HardDiskDrive).cylinders = NSNumber(BXImage.numberOfCylindersForImageWithSize(inMB: UInt(size)))
                    
                    // perform segue and hide HUD after delay (segue will modify entity)
                    
                    let delayInSeconds = 2
                    let dispatchTime = DispatchTime.now() + Double((Int64(delayInSeconds) * Int64(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                    
                    DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                        
                        self.tableView.isUserInteractionEnabled = true
                        
                        // hide progress HUD
                        MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                        
                        // perform segue
                        self.performSegue(withIdentifier: "unwindFromNewHDDImageSegue", sender: self)
                        
                        return
                    })
                })
                
            })
        }))
        
        // show
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.files.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellReusableIdentifier.FileNameCell.rawValue, for: indexPath) as UITableViewCell
        
        // get model object
        let file = self.files[indexPath.row]
        
        // configure cell
        cell.textLabel!.text = (file as NSString).lastPathComponent
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        // get file
        let fileName = self.files[indexPath.row]
        
        let fileURL = documentsURL.appendingPathComponent(fileName)
        
        switch editingStyle {
            
        case .delete:
            
            let error: NSError?
            do{
                try FileManager.default.removeItem(at: fileURL)
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
            self.files.remove(at: indexPath.row)
            
            // remove table view cell row with animation
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            tableView.endUpdates()
            
        default:
            abort()
        }
    }
    
    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "unwindFromFileSelectionSegue" {
            
            // save values...
            
            let cell = sender as! UITableViewCell
            
            self.drive?.fileName = self.files[self.tableView.indexPath(for: cell)!.row]
        }
        
    }
}

// MARK: - Private Enumerations

private enum TableViewCellReusableIdentifier: String {
    
    case FileNameCell = "FileNameCell"
}
