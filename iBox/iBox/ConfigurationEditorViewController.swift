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
            
            if configuration != nil && self.isViewLoaded {
                
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
    
    fileprivate func loadUI(forConfiguration configuration: Configuration) {
        
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
        
        vgaUpdateIntervalTextField.text = "\(configuration.vgaUpdateInterval.intValue)"
        
        soundBlaster16Switch.isOn = configuration.soundBlaster16.boolValue
        
        sdlSiwtch.isOn = configuration.sdlEnabled.boolValue
        
        feedbackSwitch.isOn = configuration.feedbackEnabled.boolValue
        
        dmaTimerTextField.text = "\(configuration.dmaTimer.intValue)"
        
        keyBoardPasteDelayTextField.text = "\(configuration.keyboardPasteDelay.intValue)"
        
        keyboardSerialDelayTextField.text = "\(configuration.keyboardSerialDelay.intValue)"
        
        networkSwitch.isOn = configuration.networkEnabled.boolValue
        
        macTextField.text = configuration.macAddress
    }
    
    // MARK: - Actions
    
    @IBAction func save(_ sender: AnyObject) {
        
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

        configuration.ramSize = NSNumber(integerLiteral: Int(UInt(self.ramSlider.value)))
        
        configuration.cpuIPS = NSNumber(integerLiteral: Int(self.ipsTextField.text!)!)
        
        switch self.vgaExtensionSegmentedControl.selectedSegmentIndex {
        case 0: configuration.vgaExtension = "none"
        case 1: configuration.vgaExtension = "vbe"
        case 2: configuration.vgaExtension = "cirrus"
        default: configuration.vgaExtension = "none"
        }
        
        configuration.vgaUpdateInterval = NSNumber(integerLiteral: Int(self.vgaUpdateIntervalTextField.text!)!)
        
        configuration.soundBlaster16 = self.soundBlaster16Switch.isOn as NSNumber
        
        configuration.sdlEnabled = self.sdlSiwtch.isOn as NSNumber
        
        configuration.feedbackEnabled = self.feedbackSwitch.isOn as NSNumber
        
        configuration.dmaTimer = NSNumber(integerLiteral: Int(self.dmaTimerTextField.text!)!)
        
        configuration.keyboardPasteDelay = NSNumber(integerLiteral: Int(self.keyBoardPasteDelayTextField.text!)!)
        
        configuration.keyboardSerialDelay = NSNumber(integerLiteral: Int(self.keyboardSerialDelayTextField.text!)!)
        
        configuration.networkEnabled = self.networkSwitch.isOn as NSNumber
        
        configuration.macAddress = self.macTextField.text!
        
        // save (will also validate)
        
        var error: NSError?
        
        do {
            try Store.sharedInstance.managedObjectContext.save()
        } catch let error1 as NSError {
            error = error1
        };
        
        if error != nil {
            
            let alertController = UIAlertController(title: NSLocalizedString("Error", comment: "Error"), message: NSLocalizedString("Could not save configuration.", comment: "Could not save configuration.") + " \\(\(error!.localizedDescription)\\)", preferredStyle: UIAlertControllerStyle.alert)
            
            self.present(alertController, animated: true, completion: nil)
            
            return
        }
        
        // dismiss VC
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        
        Store.sharedInstance.managedObjectContext.rollback()
        
        self.dismiss(animated: true, completion: nil);
    }
    
    @IBAction func ramSliderValueChanged(_ sender: UISlider) {
                
        ramLabel.text = "RAM: \(UInt(sender.value))"
    }
    
    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showDrives" {
            
            let drivesVC = segue.destination as! DrivesViewController
            
            drivesVC.configuration = self.configuration
        }
    }
    
    
    
}
