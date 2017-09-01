//
//  EmulatorViewController.swift
//  iBox
//
//  Created by Alsey Coleman Miller on 11/9/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import UIKit
import CoreData
import BochsKit

private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL?

class EmulatorViewController: UIViewController {
    
    // MARK: - IB Outlets
    
    @IBOutlet weak var renderContainerView: UIView!

    @IBOutlet weak var extrasContainerView: UIView!
    
    // MARK: - Properties
    
    var isKeyboardHide = false
    var configuration: Configuration?
    var generator: UISelectionFeedbackGenerator?
    var generator2: UINotificationFeedbackGenerator?

    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.generator = UISelectionFeedbackGenerator()
        self.generator2 = UINotificationFeedbackGenerator()
        // add render view
        
        self.view.addSubview(BXRenderView.sharedInstance())
        
        BXRenderView.sharedInstance().isMultipleTouchEnabled = true
        
        //Buttons
        self.shift1.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        self.shift2.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        self.etcBtn.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        
        // start emulator
        Thread.detachNewThreadSelector(#selector(EmulatorViewController.startEmulator), toTarget: self, with: nil)
        
        Thread.detachNewThreadSelector(#selector(EmulatorViewController.startRendering), toTarget: self, with: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // hide navigation bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    // MARK: - View Layout
    
    override func viewDidLayoutSubviews() {
        isKeyboardHide = false
        BXRenderView.sharedInstance().frame = self.renderContainerView.frame
    }
    
    
    @IBOutlet weak var keyboardContainer: UIView!
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) { //temporary "hide"
        if !isKeyboardHide {
            var newFrame: CGRect = BXRenderView.sharedInstance().frame
            newFrame.size.height += keyboardContainer.frame.size.width * 1.5
            isKeyboardHide = true
            BXRenderView.sharedInstance().frame = newFrame
            BXRenderView.sharedInstance().rescaleFrame()
            generator2?.notificationOccurred(.success)
        }
    }
    
    // MARK: - Methods
    
    @IBAction func aDown(_ sender: AnyObject) { //Deprecated
    }
    
    @IBOutlet weak var shift1: UIButton!
    @IBOutlet weak var shift2: UIButton!
    @IBOutlet weak var etcBtn: UIButton!
    
    var shifted: Bool! = false
    var etcced: Bool! = false
    
    @IBAction func keyDown(_ sender: UIButton) {
        if configuration?.feedbackEnabled.boolValue == true {
            self.generator!.selectionChanged()
        }
        if sender.tag == 200 { //etc
            if self.etcced == true {
                self.etcced = false
                self.etcBtn.layer.shadowOpacity = 0.0
                self.extrasContainerView.isHidden = true
            } else {
                self.etcced = true
                self.etcBtn.layer.shadowOpacity = 0.3
                self.extrasContainerView.isHidden = false
            }
        } else if sender.tag == 1 { //shift
            if self.shifted == true {
                self.shift1.layer.shadowOpacity = 0.0
                self.shift2.layer.shadowOpacity = 0.0
                self.shifted = false
                BXRenderView.sharedInstance().vKeyUp(Int32(sender.tag))
            } else {
                self.shift1.layer.shadowOpacity = 0.3
                self.shift2.layer.shadowOpacity = 0.3
                
                self.shifted = true
                BXRenderView.sharedInstance().vKeyDown(Int32(sender.tag))
            }
        } else {
            if shifted == true {
                switch sender.tag {
                    case 8:
                        BXRenderView.sharedInstance().vKeyUp(Int32(1))
                        BXRenderView.sharedInstance().vKeyDown(Int32(97))
                    break
                    case 9:
                        BXRenderView.sharedInstance().vKeyUp(Int32(1))
                        BXRenderView.sharedInstance().vKeyDown(Int32(95))
                    break
                    case 10:
                        BXRenderView.sharedInstance().vKeyUp(Int32(1))
                        BXRenderView.sharedInstance().vKeyDown(Int32(96))
                    break
                    case 11:
                        BXRenderView.sharedInstance().vKeyUp(Int32(1))
                        BXRenderView.sharedInstance().vKeyDown(Int32(98))
                    break
                    case 12:
                        BXRenderView.sharedInstance().vKeyUp(Int32(1))
                        BXRenderView.sharedInstance().vKeyDown(Int32(80))
                    break
                    case 13:
                        BXRenderView.sharedInstance().vKeyUp(Int32(1))
                        BXRenderView.sharedInstance().vKeyDown(Int32(81))
                    break
                    default:
                        BXRenderView.sharedInstance().vKeyDown(Int32(1))
                        BXRenderView.sharedInstance().vKeyDown(Int32(sender.tag))
                    break
                }
            } else {
                BXRenderView.sharedInstance().vKeyDown(Int32(sender.tag))
            }
        }
    }
    
    @IBAction func keyUp(_ sender: UIButton) {
        if sender.tag != 1 && sender.tag != 200 {
            if shifted == true {
                switch sender.tag {
                case 8:
                    BXRenderView.sharedInstance().vKeyUp(Int32(97))
                    break
                case 9:
                    BXRenderView.sharedInstance().vKeyUp(Int32(95))
                    break
                case 10:
                    BXRenderView.sharedInstance().vKeyUp(Int32(96))
                    break
                case 11:
                    BXRenderView.sharedInstance().vKeyUp(Int32(98))
                    break
                case 12:
                    BXRenderView.sharedInstance().vKeyUp(Int32(80))
                    break
                case 13:
                    BXRenderView.sharedInstance().vKeyUp(Int32(81))
                    break
                default:
                    BXRenderView.sharedInstance().vKeyUp(Int32(sender.tag))
                    break
                }
            } else {
                BXRenderView.sharedInstance().vKeyUp(Int32(sender.tag))
            }

        }
    }
    
    func startEmulator() {
        
        let configFilePath = self.exportConfigurationToTemporaryFile(self.configuration!)
        
        BXEmulator.startBochs(withConfigPath: configFilePath);
    }
    
    func startRendering() {
        
        let timer = Timer(timeInterval: 0.01, target: self, selector: #selector(EmulatorViewController.redrawRenderer), userInfo: nil, repeats: true)
        
        RunLoop.current.add(timer, forMode: RunLoopMode.defaultRunLoopMode)
        RunLoop.current.run()
    }
    
    func redrawRenderer() {
        
        BXRenderView.sharedInstance().doRedraw()
    }
    
    func exportConfigurationToTemporaryFile(_ configuration: Configuration) -> String {
        
        var configString = "config_interface: textconfig\n"
        configString += "display_library: nogui\n"
        configString += "megs: \(configuration.ramSize.int32Value)\n"
        configString += "boot: \(configuration.bootDevice)\n"
        configString += "pci: enabled=1, chipset=i440fx\n" //auto assign
        
        // add drives...
        
        if configuration.ataInterfaces != nil {
            
            let interfaces = configuration.ataInterfaces!.sortedArray(using: [NSSortDescriptor(key: "id", ascending: true)]) as! [ATAInterface]
            
            // add ATA interfaces
                
            for ataInterface in interfaces {
                
                configString += "ata\(ataInterface.id): enabled=1, "
                
                let drives = ataInterface.drives!.sortedArray(using: [NSSortDescriptor(key: "master", ascending: false)]) as! [Drive]
                
                //add second address
                configString += "ioaddr1=0x1f0, ioaddr2=0x3f0, "
                
                // add IRQ
                configString += "irq=\(ataInterface.irq)\n"
                
                // add drives
                
                for drive in drives {
                    
                    // master
                    var driveMasterString: String?
                    
                    if drive.master.boolValue {
                        
                        driveMasterString = "master"
                    }
                    else {
                        
                        driveMasterString = "slave"
                    }
                    
                    // type
                    var driveType:String?
                    
                    let driveEntity = DriveEntity(rawValue: drive.entity.name!)!
                    
                    switch driveEntity {
                        
                    case .CDRom: driveType = "cdrom"
                    case .HardDiskDrive: driveType = "disk"
                    case .FloppyDrive: driveType = "floppy"
                    }
                    
                    // path and info
                    let driveFilePath = documentsURL!.appendingPathComponent(drive.fileName).path
                    
                    if driveType != "floppy" {
                        configString += "ata\(ataInterface.id)-\(driveMasterString!): type=\(driveType!), path=\"\(driveFilePath)\""
                    } else {
                        configString += "floppya: 1_44=\"\(driveFilePath)\""
                    }
                    // drive specific info
                    switch driveEntity {
                        
                    case .CDRom:
                        
                        let cdrom = drive as! CDRom
                        
                        var insertedString: String?
                        
                        if cdrom.discInserted.boolValue {
                            
                            insertedString = "inserted"
                        }
                        else {
                            
                            insertedString = "ejected"
                        }
                        
                        configString += ", status=\(insertedString!)"
                       
                    break
                    case .HardDiskDrive:
                        
                        //let hdd = drive as! HardDiskDrive
                        
                        //configString += "mode=flat, cylinders=\(hdd.cylinders), heads=\(hdd.heads), spt=\(hdd.sectorsPerTrack)" Detect it automatically pls
                    break
                    case .FloppyDrive:
                        let floppy = drive as! FloppyDrive
                        
                        var insertedString: String?
                        
                        if floppy.discInserted.boolValue {
                            
                            insertedString = "inserted"
                        }
                        else {
                            
                            insertedString = "ejected"
                        }
                        
                        configString += ", status=\(insertedString!)"
                    break
                    }
                    
                    // add newline
                    configString += "\n"
                }
            }
        }
        
        
        // add other parameters
        if configuration.sdlEnabled.boolValue {
            configString += "sound: driver=sdl" + "\n"
        } else {
            configString += "sound: driver=dummy" + "\n"
        }
        
        if configuration.soundBlaster16.boolValue {
            
            configString += "sb16: enabled = 1, midimode=1, wavemode=1, dmatimer=\(configuration.dmaTimer.intValue)" + "\n"
        }
        
        //ENABLE THE NETWORK
        if configuration.networkEnabled.boolValue {
            configString += "ne2k: ioaddr=0x300, mac=\(configuration.macAddress)" + ", ethmod=fbsd, ethdev=vnet\n"
        }
        
        configString += "floppy_bootsig_check: disabled=1" + "\n"
        configString += "vga: extension=\(configuration.vgaExtension), update_freq=\(configuration.vgaUpdateInterval.intValue)" + "\n"
        
        configString += "voodoo: enabled=1, model=voodoo1" + "\n"
        
        configString += "cpu: count=1, model=corei5_arrandale_m520" + "\n" //no way to change cpu yet :)
        configString += "mouse: enabled=1, type=ps2" + "\n"
        configString += "clock: sync=none, time0=local" + "\n"
        configString += "log: -\n"
        configString += "logprefix: %i - %e%d" + "\n"
        configString += "debugger_log: -" + "\n"
        configString += "panic: action=report"  + "\n"
        configString += "error: action=report" + "\n"
        configString += "info: action=report" + "\n"
        configString += "debug: action=ignore" + "\n"
        configString += "keyboard: type=mf, keymap=0, serial_delay=\(configuration.keyboardSerialDelay.intValue), paste_delay=\(configuration.keyboardPasteDelay.intValue)" + "\n"
        configString += "user_shortcut: keys=none" + "\n"
        
        // add bios file paths
        
        let bochsKitBundle = Bundle(identifier: "com.bochs.BochsKit")!
        
        let biosPath = bochsKitBundle.url(forResource: "BIOS-bochs-latest", withExtension: nil)!.path
        
        let vgaBiosPath = (configuration.vgaExtension == "cirrus") ? bochsKitBundle.url(forResource: "VGABIOS-lgpl-latest-cirrus", withExtension: nil)!.path : bochsKitBundle.url(forResource: "VGABIOS-lgpl-latest", withExtension: nil)!.path
        
        configString += "romimage: file=\"\(biosPath)\", address=0x00000 \nvgaromimage: file=\"\(vgaBiosPath)\""
        
        let path = (URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)).appendingPathComponent("os").appendingPathExtension("ini")
        
        print("Writing temporary configuration file:\n\(configString)")
        
        // write to disc
        var error: NSError?
        do {
            try configString.write(toFile: (path.path), atomically: true, encoding: String.Encoding.utf8)
        } catch let error1 as NSError {
            error = error1
        }
        
        assert(error == nil, "Could not write temporary configuration file to disk. (\(error!.localizedDescription))")
        
        return (path.path)
    }
}
