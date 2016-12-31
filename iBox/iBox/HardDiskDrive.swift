//
//  HardDiskDrive.swift
//  iBox
//
//  Created by Alsey Coleman Miller on 11/1/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

class HardDiskDrive: Drive {

    @NSManaged var cylinders: NSNumber
    @NSManaged var heads: NSNumber
    @NSManaged var sectorsPerTrack: NSNumber

}
