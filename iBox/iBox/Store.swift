//
//  Store.swift
//  iBox
//
//  Created by Alsey Coleman Miller on 11/1/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

struct Static {
    static var onceToken : Int = 0
    static var instance : Store? = nil
}

final public class Store {
    
    private static var __once: () = {
            Static.instance = Store()
        }()
    
    // MARK: - Properties
    
    public let managedObjectContext: NSManagedObjectContext
    
    // MARK: - Initialization
    
    public class var sharedInstance : Store {
        _ = Store.__once
        return Static.instance!
    }
    
    init() {
        
        self.managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        self.managedObjectContext.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel.mergedModel(from: nil)!)
        
        // get file url
        let appSupportURL = (FileManager.default.urls(for: FileManager.SearchPathDirectory.libraryDirectory, in: .userDomainMask) as [URL]).last!
        
        let fileURL = appSupportURL.appendingPathComponent("data.sqlite")
        
        // load persistent store
        
        do {
            try self.managedObjectContext.persistentStoreCoordinator?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: fileURL, options: nil)
        } catch {
            
        }
        
    }
}
