//
//  Drive.swift
//  iBox
//
//  Created by Alsey Coleman Miller on 11/1/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

class Drive: NSManagedObject {

    @NSManaged var fileName: String
    @NSManaged var master: NSNumber
    @NSManaged var ioAddress: String
    @NSManaged var ataInterface: ATAInterface

}

// MARK: - Enumerations

enum DriveEntity: String {
    
    case CDRom = "CDRom"
    case HardDiskDrive = "HardDiskDrive"
    case FloppyDrive = "FloppyDrive"
}
