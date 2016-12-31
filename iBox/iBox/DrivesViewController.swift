//
//  DrivesViewController.swift
//  iBox
//
//  Created by Alsey Coleman Miller on 11/1/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import UIKit
import CoreData

internal let maxATAInterfacesPerConfiguration = ((Store.sharedInstance.managedObjectContext.persistentStoreCoordinator!.managedObjectModel.entitiesByName["Configuration"] as NSEntityDescription?)!.relationshipsByName["ataInterfaces"] as NSRelationshipDescription?)!.maxCount

internal let maxDrivesPerATAInterface = ((Store.sharedInstance.managedObjectContext.persistentStoreCoordinator!.managedObjectModel.entitiesByName["ATAInterface"] as NSEntityDescription?)!.relationshipsByName["drives"] as NSRelationshipDescription?)!.maxCount

class DrivesViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    // MARK: - Properties
    
    var configuration: Configuration? {
        didSet {
            
            if configuration != nil && self.isViewLoaded() {
                
                // create fetched results controller
                self.fetchedResultsController = self.fetchedResultsControllerForConfiguration(self.configuration!)
                
                do {
                    // fetch and load UI
                    try self.fetchedResultsController!.performFetch()
                } catch _ {
                }
            }
        }
    }
    
    // MARK: - Private Properties
    
    private var fetchedResultsController: NSFetchedResultsController?
    
    // MARK: - Loading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // register section header nib
        self.tableView.registerNib(UINib(nibName: "ATAInterfaceTableViewHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "ATAInterfaceTableViewHeaderView")
        
        if self.configuration != nil {
            
            // create fetched results controller
            self.fetchedResultsController = self.fetchedResultsControllerForConfiguration(self.configuration!)
            
            do {
                // fetch and load UI
                try self.fetchedResultsController!.performFetch()
            } catch _ {
            }
        }
    }
    
    // MARK: - Actions
    
    func irqStepperValueDidChange(sender: UIStepper) {
        
        // get model object
        let sectionInfo = self.fetchedResultsController!.sections![sender.tag] as NSFetchedResultsSectionInfo
        
        let section = sectionInfo.objects as! [Drive]
        let drive = section.first!
        let ataInterface = drive.ataInterface
        
        // set model object
        ataInterface.irq = Int(sender.value)
        
        // get header view
        let headerView = self.tableView.headerViewForSection(sender.tag) as! ATAInterfaceTableViewHeaderView
        
        // set up header view
        headerView.irqLabel.text = NSLocalizedString("IRQ", comment: "IRQ") + " \(ataInterface.irq.integerValue)"
    }
    
    // MARK: - Private Methods
    
    private func fetchedResultsControllerForConfiguration(configuration: Configuration) -> NSFetchedResultsController {
        
        // create fetch request
        let fetchRequest = NSFetchRequest(entityName: "Drive");
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "ataInterface.id", ascending: true), NSSortDescriptor(key: "master", ascending: false)]
        
        fetchRequest.predicate = NSPredicate(format: "ataInterface.configuration == %@", configuration)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: Store.sharedInstance.managedObjectContext, sectionNameKeyPath: "ataInterface.id", cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        // return fetched results controller
        return fetchedResultsController
    }
    
    private func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        
        // get model object
        let drive = self.fetchedResultsController?.objectAtIndexPath(indexPath) as! Drive
        
        // set type label
        if drive.master.boolValue {
            
            cell.textLabel!.text = NSLocalizedString("Master", comment: "Master")
        }
        else {
            
            cell.textLabel!.text = NSLocalizedString("Slave", comment: "Slave")
        }
        
        
        // set media label
        switch drive.entity.name! {
        case "CDRom": cell.detailTextLabel?.text = NSLocalizedString("CDROM", comment: "CDROM")
        case "HardDiskDrive": cell.detailTextLabel?.text = NSLocalizedString("HDD", comment: "HDD")
        case "FloppyDrive": cell.detailTextLabel?.text = NSLocalizedString("Floppy", comment: "Floppy")
        default: cell.detailTextLabel?.text = NSLocalizedString("Unknown", comment: "Unknown")
        }
    }
    
    private func canCreateNewDrive() -> Bool {
        
        if self.configuration!.ataInterfaces?.count > 0 {
            
            // only 4 ATA interfaces max
            if self.configuration!.ataInterfaces?.count > maxATAInterfacesPerConfiguration {
                
                return false
            }
            
            // cannot create ATA interface with id higher than max...
            
            // find latest ATA interface
            
            let fetchRequest = NSFetchRequest(entityName: "ATAInterface")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
            fetchRequest.predicate = NSPredicate(format: "configuration == %@", self.configuration!)
            
            var fetchError: NSError?
            let fetchResult: [AnyObject]?
            do {
                fetchResult = try Store.sharedInstance.managedObjectContext.executeFetchRequest(fetchRequest)
            } catch var error as NSError {
                fetchError = error
                fetchResult = nil
            }
            
            assert(fetchError == nil, "Error occurred while fetching from store. (\(fetchError?.localizedDescription))")
            
            let newestATAInterface = fetchResult!.last as! ATAInterface
            
            // max number of interfaces and drives
            if newestATAInterface.id == maxATAInterfacesPerConfiguration - 1 && newestATAInterface.drives?.count == maxDrivesPerATAInterface {
                
                return false
            }
        }
        
        return true
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        if let numberOfSections = self.fetchedResultsController?.sections?.count {
            
            // conditionaly enable add button
            if let addButton = self.navigationItem.rightBarButtonItem {
                
                self.navigationItem.rightBarButtonItem?.enabled = self.canCreateNewDrive()
            }
            
            // return number of section
            return numberOfSections
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let sectionInfo = self.fetchedResultsController!.sections![section] as NSFetchedResultsSectionInfo
        
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let DriveCellIdentifier = "DriveCell"
        
        let cell = tableView.dequeueReusableCellWithIdentifier(DriveCellIdentifier, forIndexPath: indexPath) as UITableViewCell
        
        self.configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = tableView.dequeueReusableHeaderFooterViewWithIdentifier("ATAInterfaceTableViewHeaderView") as! ATAInterfaceTableViewHeaderView
        
        // get model object
        let sectionInfo = self.fetchedResultsController!.sections![section] as NSFetchedResultsSectionInfo
        let sectionArray = sectionInfo.objects as! [Drive]
        let drive = sectionArray.first!
        let ataInterface = drive.ataInterface;
        
        // configure header view
        headerView.ataLabel.text = NSLocalizedString("ATA Interface", comment: "ATA Interface") + " \(ataInterface.id.integerValue)"
        headerView.irqLabel.text = NSLocalizedString("IRQ", comment: "IRQ") + " \(ataInterface.irq.integerValue)"
        headerView.irqStepper.value = ataInterface.irq.doubleValue
        headerView.irqStepper.addTarget(self, action: "irqStepperValueDidChange:", forControlEvents: UIControlEvents.ValueChanged)
        headerView.irqStepper.tag = section
        
        return headerView
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == UITableViewCellEditingStyle.Delete {
            
            // get the model object
            let drive = self.fetchedResultsController!.objectAtIndexPath(indexPath) as! Drive
            let ataInterface = drive.ataInterface
            
            // delete drive
            Store.sharedInstance.managedObjectContext.deleteObject(drive)
            
            // also delete ATA interface if it is empty or deleted drive is master...
            
            if ataInterface.drives!.count == 0 || drive.master.boolValue {
                
                Store.sharedInstance.managedObjectContext.deleteObject(ataInterface)
            }

        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 95
    }
    
    // MARK: - NSFetchedResultsController
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
        case .Update:
            self.configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, atIndexPath: indexPath!)
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
        default:
            return
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
    
    // MARK: - Segues
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        
        if identifier == "newDriveSegue" {
            
            return self.canCreateNewDrive()
        }
        
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "newDriveSegue" {
            
            // get VC
            let newDriveVC = (segue.destinationViewController as! UINavigationController).viewControllers.first as! NewDriveViewController
            
            // set model object on VC
            newDriveVC.configuration = self.configuration!
        }
        
        if segue.identifier == "editDriveSegue" {
            
            // get selected drive
            let selectedDrive = self.fetchedResultsController!.objectAtIndexPath(self.tableView.indexPathForSelectedRow!) as! Drive
            
            // set model object on VC
            let driveEditorVC = segue.destinationViewController as! DriveEditorViewController
            
            driveEditorVC.drive = selectedDrive
            
            // hide done button
            driveEditorVC.navigationItem.rightBarButtonItem = nil
        }
    }
    
    @IBAction func unwindFromNewHDDImage(segue: UIStoryboardSegue) { }
    
}

// MARK: - UI Classes

class ATAInterfaceTableViewHeaderView: UITableViewHeaderFooterView {
    
    // Use to bind to IB, but remove for compiling
    //@IBOutlet var contentView: UIView!
    
    @IBOutlet weak var ataLabel: UILabel!
    
    @IBOutlet weak var irqLabel: UILabel!
    
    @IBOutlet weak var irqStepper: UIStepper!
    
}
