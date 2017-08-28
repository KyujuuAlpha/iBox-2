//
//  DrivesViewController.swift
//  iBox
//
//  Created by Alsey Coleman Miller on 11/1/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import UIKit
import CoreData
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


internal let maxATAInterfacesPerConfiguration = ((Store.sharedInstance.managedObjectContext.persistentStoreCoordinator!.managedObjectModel.entitiesByName["Configuration"] as NSEntityDescription?)!.relationshipsByName["ataInterfaces"] as NSRelationshipDescription?)!.maxCount

internal let maxDrivesPerATAInterface = ((Store.sharedInstance.managedObjectContext.persistentStoreCoordinator!.managedObjectModel.entitiesByName["ATAInterface"] as NSEntityDescription?)!.relationshipsByName["drives"] as NSRelationshipDescription?)!.maxCount

class DrivesViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    // MARK: - Properties
    
    var configuration: Configuration? {
        didSet {
            
            if configuration != nil && self.isViewLoaded {
                
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
    
    fileprivate var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    
    // MARK: - Loading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // register section header nib
        self.tableView.register(UINib(nibName: "ATAInterfaceTableViewHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "ATAInterfaceTableViewHeaderView")
        
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
    
    func irqStepperValueDidChange(_ sender: UIStepper) {
        
        // get model object
        let sectionInfo = self.fetchedResultsController!.sections![sender.tag] as NSFetchedResultsSectionInfo
        
        let section = sectionInfo.objects as! [Drive]
        let drive = section.first!
        let ataInterface = drive.ataInterface
        
        // set model object
        ataInterface.irq = NSNumber(value: Int(sender.value))
        
        // get header view
        let headerView = self.tableView.headerView(forSection: sender.tag) as! ATAInterfaceTableViewHeaderView
        
        // set up header view
        headerView.irqLabel.text = NSLocalizedString("IRQ", comment: "IRQ") + " \(ataInterface.irq.intValue)"
    }
    
    // MARK: - Private Methods
    
    fileprivate func fetchedResultsControllerForConfiguration(_ configuration: Configuration) -> NSFetchedResultsController<NSFetchRequestResult> {
        
        // create fetch request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Drive");
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "ataInterface.id", ascending: true), NSSortDescriptor(key: "master", ascending: false)]
        
        fetchRequest.predicate = NSPredicate(format: "ataInterface.configuration == %@", configuration)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: Store.sharedInstance.managedObjectContext, sectionNameKeyPath: "ataInterface.id", cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        // return fetched results controller
        return fetchedResultsController
    }
    
    fileprivate func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        
        // get model object
        let drive = self.fetchedResultsController?.object(at: indexPath) as! Drive
        
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
    
    fileprivate func canCreateNewDrive() -> Bool {
        
        if self.configuration!.ataInterfaces?.count > 0 {
            
            // only 4 ATA interfaces max
            if self.configuration!.ataInterfaces?.count > maxATAInterfacesPerConfiguration {
                
                return false
            }
            
            // cannot create ATA interface with id higher than max...
            
            // find latest ATA interface
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ATAInterface")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
            fetchRequest.predicate = NSPredicate(format: "configuration == %@", self.configuration!)
            
            var fetchError: NSError?
            let fetchResult: [AnyObject]?
            do {
                fetchResult = try Store.sharedInstance.managedObjectContext.fetch(fetchRequest)
            } catch let error as NSError {
                fetchError = error
                fetchResult = nil
            }
            
            assert(fetchError == nil, "Error occurred while fetching from store. (\(fetchError?.localizedDescription ?? "nil"))")
            
            let newestATAInterface = fetchResult!.last as! ATAInterface
            
            // max number of interfaces and drives
            if newestATAInterface.id == NSNumber(value: maxATAInterfacesPerConfiguration - 1) && newestATAInterface.drives?.count == maxDrivesPerATAInterface {
                
                return false
            }
        }
        
        return true
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if let numberOfSections = self.fetchedResultsController?.sections?.count {
            
            // conditionaly enable add button
            if self.navigationItem.rightBarButtonItem != nil {
                
                self.navigationItem.rightBarButtonItem?.isEnabled = self.canCreateNewDrive()
            }
            
            // return number of section
            return numberOfSections
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let sectionInfo = self.fetchedResultsController!.sections![section] as NSFetchedResultsSectionInfo
        
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let DriveCellIdentifier = "DriveCell"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: DriveCellIdentifier, for: indexPath) as UITableViewCell
        
        self.configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "ATAInterfaceTableViewHeaderView") as! ATAInterfaceTableViewHeaderView
        
        // get model object
        let sectionInfo = self.fetchedResultsController!.sections![section] as NSFetchedResultsSectionInfo
        let sectionArray = sectionInfo.objects as! [Drive]
        let drive = sectionArray.first!
        let ataInterface = drive.ataInterface;
        
        // configure header view
        headerView.ataLabel.text = NSLocalizedString("ATA Interface", comment: "ATA Interface") + " \(ataInterface.id.intValue)"
        headerView.irqLabel.text = NSLocalizedString("IRQ", comment: "IRQ") + " \(ataInterface.irq.intValue)"
        headerView.irqStepper.value = ataInterface.irq.doubleValue
        headerView.irqStepper.addTarget(self, action: #selector(DrivesViewController.irqStepperValueDidChange(_:)), for: UIControlEvents.valueChanged)
        headerView.irqStepper.tag = section
        
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == UITableViewCellEditingStyle.delete {
            
            // get the model object
            let drive = self.fetchedResultsController!.object(at: indexPath) as! Drive
            let ataInterface = drive.ataInterface
            
            // delete drive
            Store.sharedInstance.managedObjectContext.delete(drive)
            
            // also delete ATA interface if it is empty or deleted drive is master...
            
            if ataInterface.drives!.count == 0 || drive.master.boolValue {
                
                Store.sharedInstance.managedObjectContext.delete(ataInterface)
            }

        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 95
    }
    
    // MARK: - NSFetchedResultsController
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: UITableViewRowAnimation.fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: UITableViewRowAnimation.fade)
        case .update:
            self.configureCell(tableView.cellForRow(at: indexPath!)!, atIndexPath: indexPath!)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: UITableViewRowAnimation.fade)
            tableView.insertRows(at: [newIndexPath!], with: UITableViewRowAnimation.fade)
        default:
            return
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    
    // MARK: - Segues
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        if identifier == "newDriveSegue" {
            
            return self.canCreateNewDrive()
        }
        
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "newDriveSegue" {
            
            // get VC
            let newDriveVC = (segue.destination as! UINavigationController).viewControllers.first as! NewDriveViewController
            
            // set model object on VC
            newDriveVC.configuration = self.configuration!
        }
        
        if segue.identifier == "editDriveSegue" {
            
            // get selected drive
            let selectedDrive = self.fetchedResultsController!.object(at: self.tableView.indexPathForSelectedRow!) as! Drive
            
            // set model object on VC
            let driveEditorVC = segue.destination as! DriveEditorViewController
            
            driveEditorVC.drive = selectedDrive
            
            // hide done button
            driveEditorVC.navigationItem.rightBarButtonItem = nil
        }
    }
    
    @IBAction func unwindFromNewHDDImage(_ segue: UIStoryboardSegue) { }
    
}

// MARK: - UI Classes

class ATAInterfaceTableViewHeaderView: UITableViewHeaderFooterView {
    
    // Use to bind to IB, but remove for compiling
    //@IBOutlet var contentView: UIView!
    
    @IBOutlet weak var ataLabel: UILabel!
    
    @IBOutlet weak var irqLabel: UILabel!
    
    @IBOutlet weak var irqStepper: UIStepper!
    
}
