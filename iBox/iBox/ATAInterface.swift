//
//  ATAInterface.swift
//  iBox
//
//  Created by Alsey Coleman Miller on 11/1/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

class ATAInterface: NSManagedObject {

    @NSManaged var id: NSNumber
    @NSManaged var irq: NSNumber
    @NSManaged var configuration: Configuration
    @NSManaged var drives: NSSet?

}
