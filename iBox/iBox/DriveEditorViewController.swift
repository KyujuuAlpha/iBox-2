//
//  DriveEditorViewController.swift
//  iBox
//
//  Created by Alsey Coleman Miller on 11/1/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import UIKit
import CoreData
import BochsKit

class DriveEditorViewController: UITableViewController, UITextFieldDelegate {
    
    // MARK: - Properties
    
    var drive: Drive? {
        
        didSet {
            
            if drive != nil {
                
                let driveEntity = DriveEntity(rawValue: drive!.entity.name!)!
                
                self.updateTableViewCellLayoutForEntity(driveEntity)
            }
        }
    }
    
    // MARK: - Private Properties
    
    private var tableViewCellLayout = [[TableViewCellItem]]()
    
    // MARK: - Private Methods
    
    private func updateTableViewCellLayoutForEntity(entity: DriveEntity) {
        
        // create layout based on entity
        
        let infoSectionLayout: [TableViewCellItem] = [.FileName]
        
        var driveConfigurationSectionLayout: [TableViewCellItem]?
        
        switch entity {
            
        case .CDRom:
            
            driveConfigurationSectionLayout = [.DiscInserted]
            
        case .HardDiskDrive:
            
            driveConfigurationSectionLayout = [.Cylinders, .Heads, .SectorsPerTrack]
            
        case .FloppyDrive:
            
            driveConfigurationSectionLayout = [.DiscInserted]
        }
        
        self.tableViewCellLayout = [infoSectionLayout, driveConfigurationSectionLayout!]
        
        // reload UI
        self.tableView.reloadData()
    }
    
    // MARK: - Actions
    
    @IBAction func done(sender: UIBarButtonItem) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func switchFlipped(sender: UISwitch) {
        if ((self.drive as? CDRom) != nil) {
            (self.drive as! CDRom).discInserted = sender.on
        } else {
            (self.drive as! FloppyDrive).discInserted = sender.on
        }
        
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return self.tableViewCellLayout.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // get model object
        let sectionArray = self.tableViewCellLayout[section]
        
        return sectionArray.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // get model object
        let sectionArray = self.tableViewCellLayout[indexPath.section]
        let cellItem = sectionArray[indexPath.row]
        
        // get and configure cell
        switch cellItem {
            
        case .FileName:
            
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellReusableIdentifier.FileNameCell.rawValue, forIndexPath: indexPath) as! TextFieldCell
            
            cell.titleLabel.text = NSLocalizedString("File Name", comment: "File Name")
            
            cell.textField.text = self.drive!.fileName
            
            return cell
            
        case .DiscInserted:
            
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellReusableIdentifier.SwitchCell.rawValue, forIndexPath: indexPath) as UITableViewCell
            
            cell.textLabel!.text = NSLocalizedString("Disc Inserted", comment: "Disc Inserted")
            
            /*
            let switchControl = UISwitch()
            switchControl.addTarget(self, action: "switchFlipped:", forControlEvents: UIControlEvents.ValueChanged)
            cell.accessoryView = switchControl
            */
            if ((self.drive as? CDRom) != nil) {
                (cell.accessoryView as! UISwitch).on = (self.drive as! CDRom).discInserted.boolValue
            } else {
                (cell.accessoryView as! UISwitch).on = (self.drive as! FloppyDrive).discInserted.boolValue
            }
            
            return cell

        case .Heads:
            
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellReusableIdentifier.NumberInputCell.rawValue, forIndexPath: indexPath) as! TextFieldCell
            
            cell.titleLabel.text = NSLocalizedString("Heads", comment: "Heads")
            
            cell.textField.text = "\((self.drive as! HardDiskDrive).heads)"
            
            return cell
            
        case .Cylinders:
            
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellReusableIdentifier.NumberInputCell.rawValue, forIndexPath: indexPath) as! TextFieldCell
            
            cell.titleLabel.text = NSLocalizedString("Cylinders", comment: "Cylinders")
            
            cell.textField.text = "\((self.drive as! HardDiskDrive).cylinders)"
            
            return cell
            
        case .SectorsPerTrack:
            
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellReusableIdentifier.NumberInputCell.rawValue, forIndexPath: indexPath) as! TextFieldCell
            
            cell.titleLabel.text = NSLocalizedString("Sectors per Track", comment: "Sectors per Track")
            
            cell.textField.text = "\((self.drive as! HardDiskDrive).sectorsPerTrack)"
            
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        switch section {
            
        case 0:
            
            return NSLocalizedString("Info", comment: "Info")
            
        case 1:
            
            let driveEntity = DriveEntity(rawValue: drive!.entity.name!)!
            
            switch driveEntity {
                
            case .CDRom: return NSLocalizedString("CDROM Configuration", comment: "CDROM Configuration")
                
            case .HardDiskDrive : return NSLocalizedString("HDD Configuration", comment: "HDD Configuration")
                
            case .FloppyDrive: return NSLocalizedString("Floppy Configuration", comment: "Floppy Configuration")
                
            }
            
        default: return "Section"
            
        }
    }
    
    // MARK: - UITextFieldDelegate
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        
        // get index path of enclosing cel
        let indexPath = self.tableView.indexPathForRowAtPoint(textField.convertPoint(textField.frame.origin, toView: self.tableView))!
        
        // get model object
        let sectionArray = self.tableViewCellLayout[indexPath.section]
        let cellItem = sectionArray[indexPath.row]
        
        switch cellItem {
            
        case .FileName: self.drive!.fileName = textField.text!
        case .Heads: (self.drive as! HardDiskDrive).heads = Int(textField.text!)!
        case .Cylinders: (self.drive as! HardDiskDrive).cylinders = Int(textField.text!)!
        case .SectorsPerTrack: (self.drive as! HardDiskDrive).sectorsPerTrack = Int(textField.text!)!
        default:
            debugPrint("Text edited in cell with identifer (\(cellItem)) without a implemented case in " + __FUNCTION__)
            abort()
        }
    }
    
    // MARK: - Segues
    
    @IBAction func unwindFromFileSelection(segue: UIStoryboardSegue) {
        
        self.tableView.reloadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "fileSelectionSegue" {
            
            // set drive
            (segue.destinationViewController as! FileSelectionViewController).drive = self.drive
            
            // conditionally disable add button
            if self.drive!.entity.name != DriveEntity.HardDiskDrive.rawValue {
                
                segue.destinationViewController.navigationItem.rightBarButtonItem = nil
            }
        }
        
    }
}

// MARK: - Private Enumerations

private enum TableViewCellItem {
    
    case FileName, DiscInserted, Heads, Cylinders, SectorsPerTrack
}

private enum TableViewCellReusableIdentifier: String {
    
    case FileNameCell = "FileNameCell"
    case SwitchCell = "SwitchCell"
    case NumberInputCell = "NumberInputCell"
}
