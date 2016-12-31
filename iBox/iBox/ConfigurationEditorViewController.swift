//
//  ConfigurationEditorViewController.swift
//  iBox
//
//  Created by Alsey Coleman Miller on 10/31/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import UIKit

class ConfigurationEditorViewController: UITableViewController {
    
    // MARK: - IB Outlets
    
    @IBOutlet weak var configurationNameTextField: UITextField!
    
    @IBOutlet weak var drivesTableViewCell: UITableViewCell!
    
    @IBOutlet weak var bootDiskSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var ramLabel: UILabel!
    
    @IBOutlet weak var ramSlider: UISlider!
    
    @IBOutlet weak var ipsTextField: UITextField!
    
    @IBOutlet weak var vgaExtensionSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var vgaUpdateIntervalTextField: UITextField!
    
    @IBOutlet weak var soundBlaster16Switch: UISwitch!
    
    @IBOutlet weak var sdlSiwtch: UISwitch!
    
    @IBOutlet weak var dmaTimerTextField: UITextField!
    
    @IBOutlet weak var keyBoardPasteDelayTextField: UITextField!
    
    @IBOutlet weak var keyboardSerialDelayTextField: UITextField!
    
    @IBOutlet weak var feedbackSwitch: UISwitch!
    
    //FOR THE NETWORK
    @IBOutlet weak var networkSwitch: UISwitch!
    
    @IBOutlet weak var macTextField: UITextField!
    
    // MARK: - Properties
    
    var configuration: Configuration? {
        didSet {
            
            if configuration != nil && self.isViewLoaded() {
                
                self.loadUI(forConfiguration: self.configuration!)
            }
        }
    }
    
    // MARK: - Loading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // load UI
        if configuration != nil {
            
            self.loadUI(forConfiguration: self.configuration!)
        }
    }
    
    private func loadUI(forConfiguration configuration: Configuration) {
        
        // setup UI with values from model object...
        
        configurationNameTextField.text = configuration.name
        
        switch configuration.bootDevice {
            case "cdrom": self.bootDiskSegmentedControl.selectedSegmentIndex = 0
            case "disk": self.bootDiskSegmentedControl.selectedSegmentIndex = 1
            case "floppy": self.bootDiskSegmentedControl.selectedSegmentIndex = 2
        default : self.bootDiskSegmentedControl.selectedSegmentIndex = -1
        }
        
        ramLabel.text = "RAM: \(configuration.ramSize)"
        
        ramSlider.value = configuration.ramSize.floatValue
        
        ipsTextField.text = "\(configuration.cpuIPS)"
        
        switch configuration.vgaExtension {
            case "vbe": self.vgaExtensionSegmentedControl.selectedSegmentIndex = 1
            case "cirrus": self.vgaExtensionSegmentedControl.selectedSegmentIndex = 2
        default: self.vgaExtensionSegmentedControl.selectedSegmentIndex = 0
        }
        
        vgaUpdateIntervalTextField.text = "\(configuration.vgaUpdateInterval.integerValue)"
        
        soundBlaster16Switch.on = configuration.soundBlaster16.boolValue
        
        sdlSiwtch.on = configuration.sdlEnabled.boolValue
        
        feedbackSwitch.on = configuration.feedbackEnabled.boolValue
        
        dmaTimerTextField.text = "\(configuration.dmaTimer.integerValue)"
        
        keyBoardPasteDelayTextField.text = "\(configuration.keyboardPasteDelay.integerValue)"
        
        keyboardSerialDelayTextField.text = "\(configuration.keyboardSerialDelay.integerValue)"
        
        networkSwitch.on = configuration.networkEnabled.boolValue
        
        macTextField.text = configuration.macAddress
    }
    
    // MARK: - Actions
    
    @IBAction func save(sender: AnyObject) {
        
        assert(self.configuration != nil)
        
        let configuration = self.configuration!
        
        // get values from UI and set them to model object
        
        configuration.name = self.configurationNameTextField.text!;
        
        switch self.bootDiskSegmentedControl.selectedSegmentIndex {
        case 0: configuration.bootDevice = "cdrom"
        case 1: configuration.bootDevice = "disk"
        case 2: configuration.bootDevice = "floppy"
        default: configuration.bootDevice = "cdrom"
        }
        
        configuration.ramSize = UInt(self.ramSlider.value)
                
        configuration.cpuIPS = Int(self.ipsTextField.text!)!
        
        switch self.vgaExtensionSegmentedControl.selectedSegmentIndex {
        case 0: configuration.vgaExtension = "none"
        case 1: configuration.vgaExtension = "vbe"
        case 2: configuration.vgaExtension = "cirrus"
        default: configuration.vgaExtension = "none"
        }
        
        configuration.vgaUpdateInterval = Int(self.vgaUpdateIntervalTextField.text!)!
        
        configuration.soundBlaster16 = self.soundBlaster16Switch.on
        
        configuration.sdlEnabled = self.sdlSiwtch.on
        
        configuration.feedbackEnabled = self.feedbackSwitch.on
        
        configuration.dmaTimer = Int(self.dmaTimerTextField.text!)!
        
        configuration.keyboardPasteDelay = Int(self.keyBoardPasteDelayTextField.text!)!
        
        configuration.keyboardSerialDelay = Int(self.keyboardSerialDelayTextField.text!)!
        
        configuration.networkEnabled = self.networkSwitch.on
        
        configuration.macAddress = self.macTextField.text!
        
        // save (will also validate)
        
        var error: NSError?
        
        do {
            try Store.sharedInstance.managedObjectContext.save()
        } catch let error1 as NSError {
            error = error1
        };
        
        if error != nil {
            
            let alertController = UIAlertController(title: NSLocalizedString("Error", comment: "Error"), message: NSLocalizedString("Could not save configuration.", comment: "Could not save configuration.") + " \\(\(error!.localizedDescription)\\)", preferredStyle: UIAlertControllerStyle.Alert)
            
            self.presentViewController(alertController, animated: true, completion: nil)
            
            return
        }
        
        // dismiss VC
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancel(sender: AnyObject) {
        
        Store.sharedInstance.managedObjectContext.rollback()
        
        self.dismissViewControllerAnimated(true, completion: nil);
    }
    
    @IBAction func ramSliderValueChanged(sender: UISlider) {
                
        ramLabel.text = "RAM: \(UInt(sender.value))"
    }
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showDrives" {
            
            let drivesVC = segue.destinationViewController as! DrivesViewController
            
            drivesVC.configuration = self.configuration
        }
    }
    
    
    
}
