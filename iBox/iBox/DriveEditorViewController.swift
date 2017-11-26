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
    
    fileprivate var tableViewCellLayout = [[TableViewCellItem]]()
    
    // MARK: - Private Methods
    
    fileprivate func updateTableViewCellLayoutForEntity(_ entity: DriveEntity) {
        
        // create layout based on entity
        
        let infoSectionLayout: [TableViewCellItem] = [.fileName]
        
        var driveConfigurationSectionLayout: [TableViewCellItem]?
        
        switch entity {
            
        case .CDRom:
            
            driveConfigurationSectionLayout = [.discInserted]
            
        case .HardDiskDrive:
            
            driveConfigurationSectionLayout = [.cylinders, .heads, .sectorsPerTrack]
            
        case .FloppyDrive:
            
            driveConfigurationSectionLayout = [.discInserted]
        }
        
        self.tableViewCellLayout = [infoSectionLayout, driveConfigurationSectionLayout!]
        
        // reload UI
        self.tableView.reloadData()
    }
    
    // MARK: - Actions
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func switchFlipped(_ sender: UISwitch) {
        if ((self.drive as? CDRom) != nil) {
            (self.drive as! CDRom).discInserted = sender.isOn as NSNumber
        } else {
            (self.drive as! FloppyDrive).discInserted = sender.isOn as NSNumber
        }
        
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return self.tableViewCellLayout.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // get model object
        let sectionArray = self.tableViewCellLayout[section]
        
        return sectionArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // get model object
        let sectionArray = self.tableViewCellLayout[indexPath.section]
        let cellItem = sectionArray[indexPath.row]
        
        // get and configure cell
        switch cellItem {
            
        case .fileName:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellReusableIdentifier.FileNameCell.rawValue, for: indexPath) as! TextFieldCell
            
            cell.titleLabel.text = NSLocalizedString("File Name", comment: "File Name")
            
            cell.textField.text = self.drive!.fileName
            
            return cell
            
        case .discInserted:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellReusableIdentifier.SwitchCell.rawValue, for: indexPath) as UITableViewCell
            
            cell.textLabel!.text = NSLocalizedString("Disc Inserted", comment: "Disc Inserted")
            
            /*
            let switchControl = UISwitch()
            switchControl.addTarget(self, action: "switchFlipped:", forControlEvents: UIControlEvents.ValueChanged)
            cell.accessoryView = switchControl
            */
            if ((self.drive as? CDRom) != nil) {
                (cell.accessoryView as! UISwitch).isOn = (self.drive as! CDRom).discInserted.boolValue
            } else {
                (cell.accessoryView as! UISwitch).isOn = (self.drive as! FloppyDrive).discInserted.boolValue
            }
            
            return cell

        case .heads:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellReusableIdentifier.NumberInputCell.rawValue, for: indexPath) as! TextFieldCell
            
            cell.titleLabel.text = NSLocalizedString("Heads", comment: "Heads")
            
            cell.textField.text = "\((self.drive as! HardDiskDrive).heads)"
            
            return cell
            
        case .cylinders:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellReusableIdentifier.NumberInputCell.rawValue, for: indexPath) as! TextFieldCell
            
            cell.titleLabel.text = NSLocalizedString("Cylinders", comment: "Cylinders")
            
            cell.textField.text = "\((self.drive as! HardDiskDrive).cylinders)"
            
            return cell
            
        case .sectorsPerTrack:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellReusableIdentifier.NumberInputCell.rawValue, for: indexPath) as! TextFieldCell
            
            cell.titleLabel.text = NSLocalizedString("Sectors per Track", comment: "Sectors per Track")
            
            cell.textField.text = "\((self.drive as! HardDiskDrive).sectorsPerTrack)"
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
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
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        // get index path of enclosing cel
        let indexPath = self.tableView.indexPathForRow(at: textField.convert(textField.frame.origin, to: self.tableView))!
        
        // get model object
        let sectionArray = self.tableViewCellLayout[indexPath.section]
        let cellItem = sectionArray[indexPath.row]
        
        switch cellItem {
            
        case .fileName: self.drive!.fileName = textField.text!
        case .heads: (self.drive as! HardDiskDrive).heads = Int(textField.text!)!
        case .cylinders: (self.drive as! HardDiskDrive).cylinders = Int(textField.text!)!
        case .sectorsPerTrack: (self.drive as! HardDiskDrive).sectorsPerTrack = Int(textField.text!)!
        default:
            debugPrint("Text edited in cell with identifer (\(cellItem)) without a implemented case in " + #function)
            abort()
        }
    }
    
    // MARK: - Segues
    
    @IBAction func unwindFromFileSelection(_ segue: UIStoryboardSegue) {
        
        self.tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "fileSelectionSegue" {
            
            // set drive
            (segue.destination as! FileSelectionViewController).drive = self.drive
            
            // conditionally disable add button
            if self.drive!.entity.name != DriveEntity.HardDiskDrive.rawValue {
                
                segue.destination.navigationItem.rightBarButtonItem = nil
            }
        }
        
    }
}

// MARK: - Private Enumerations

private enum TableViewCellItem {
    
    case fileName, discInserted, heads, cylinders, sectorsPerTrack
}

private enum TableViewCellReusableIdentifier: String {
    
    case FileNameCell = "FileNameCell"
    case SwitchCell = "SwitchCell"
    case NumberInputCell = "NumberInputCell"
}
