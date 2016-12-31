//
//  Store.swift
//  iBox
//
//  Created by Alsey Coleman Miller on 11/1/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

final public class Store {
    
    // MARK: - Properties
    
    public let managedObjectContext: NSManagedObjectContext
    
    // MARK: - Initialization
    
    public class var sharedInstance : Store {
        struct Static {
            static var onceToken : dispatch_once_t = 0
            static var instance : Store? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = Store()
        }
        return Static.instance!
    }
    
    init() {
        
        self.managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        self.managedObjectContext.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel.mergedModelFromBundles(nil)!)
        
        // get file url
        let appSupportURL = (NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.LibraryDirectory, inDomains: .UserDomainMask) as [NSURL]).last!
        
        let fileURL = appSupportURL.URLByAppendingPathComponent("data.sqlite")
        
        // load persistent store
        
        do {
            try self.managedObjectContext.persistentStoreCoordinator?.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: fileURL, options: nil)
        } catch {
            
        }
        
    }
}
