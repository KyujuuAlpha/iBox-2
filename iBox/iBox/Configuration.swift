//
//  Configuration.swift
//  iBox
//
//  Created by Alsey Coleman Miller on 11/1/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

class Configuration: NSManagedObject {

    @NSManaged var bootDevice: String
    @NSManaged var cpuIPS: NSNumber
    @NSManaged var dmaTimer: NSNumber
    @NSManaged var keyboardPasteDelay: NSNumber
    @NSManaged var keyboardSerialDelay: NSNumber
    @NSManaged var feedbackEnabled: NSNumber
    @NSManaged var midiMode: NSNumber
    @NSManaged var name: String
    @NSManaged var ramSize: NSNumber
    @NSManaged var soundBlaster16: NSNumber
    @NSManaged var sdlEnabled: NSNumber
    @NSManaged var vgaExtension: String
    @NSManaged var vgaUpdateInterval: NSNumber
    @NSManaged var waveMode: NSNumber
    @NSManaged var ataInterfaces: NSSet?
    @NSManaged var networkEnabled: NSNumber
    @NSManaged var macAddress: String

}
