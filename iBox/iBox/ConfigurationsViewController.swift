//
//  ConfigurationsViewController.swift
//  iBox
//
//  Created by Alsey Coleman Miller on 10/27/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import UIKit
import CoreData

class ConfigurationsViewController: UITableViewController, UISearchBarDelegate, NSFetchedResultsControllerDelegate {
    
    // MARK: - IB Outlets
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    // MARK: - Private Properties
    
    fileprivate var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    
    // MARK: - Loading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create fetched results controller
        self.fetchedResultsController = self.fetchedResultsControllerForSearchText(nil)
        
        do {
            try self.fetchedResultsController!.performFetch()
        } catch _ {
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // clear search text
        self.searchBar.text = ""
    }
    
    // MARK: - Private Methods
    
    fileprivate func fetchedResultsControllerForSearchText(_ searchText: String?) -> NSFetchedResultsController<NSFetchRequestResult> {
        
        // create fetch request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Configuration");
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        // set predicate for search text
        if searchText != nil && searchText != "" {
            
            fetchRequest.predicate = NSPredicate(format: "name contains[c] %@", searchText!)
        }
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: Store.sharedInstance.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        // return fetched results controller
        return fetchedResultsController
    }
    
    fileprivate func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        
        // get model object
        let configuration = self.fetchedResultsController?.object(at: indexPath) as! Configuration
        
        cell.textLabel!.text = configuration.name;
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let count = self.fetchedResultsController?.fetchedObjects?.count {
            
            return count
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let ConfigurationCellIdentier = "ConfigurationCell"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ConfigurationCellIdentier, for: indexPath) as UITableViewCell
        
        self.configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        // get the model object
        let configuration = self.fetchedResultsController?.object(at: indexPath) as! Configuration
        
        // delete
        Store.sharedInstance.managedObjectContext.delete(configuration)
        
        // save
        
        var error: NSError?
        
        do {
            try Store.sharedInstance.managedObjectContext.save()
        } catch let error1 as NSError {
            error = error1
        }
        
        if error != nil {
            
            let alertController = UIAlertController(title: NSLocalizedString("Error", comment: "Error"), message: NSLocalizedString("Could not delete configuration.", comment: "Could not delete configuration.") + " \\(\(error!.localizedDescription)\\)", preferredStyle: UIAlertControllerStyle.alert)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        // update the fetched results controller
        self.fetchedResultsController = self.fetchedResultsControllerForSearchText(searchText);
        
        do {
            try self.fetchedResultsController!.performFetch()
        } catch _ {
        }
        
        self.tableView.reloadData()
    }
    
    // MARK: - NSFetchedResultsController
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: UITableViewRowAnimation.fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: UITableViewRowAnimation.fade)
        case .update:
            self.configureCell(tableView.cellForRow(at: indexPath!)!, atIndexPath: indexPath!)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: UITableViewRowAnimation.fade)
            tableView.insertRows(at: [newIndexPath!], with: UITableViewRowAnimation.fade)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    
    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "newConfigurationSegue" {
            
            // create new configuration
            
            let newConfiguration = NSEntityDescription.insertNewObject(forEntityName: "Configuration", into: Store.sharedInstance.managedObjectContext) as! Configuration
            
            let configurationEditorVC = (segue.destination as! UINavigationController).viewControllers.first as! ConfigurationEditorViewController
            
            configurationEditorVC.configuration = newConfiguration
        }
        
        if segue.identifier == "editConfigurationSegue" {
            
            // edit configuration
            
            let configuration = self.fetchedResultsController?.object(at: self.tableView.indexPath(for: sender as! UITableViewCell)!) as! Configuration
            
            let configurationEditorVC = (segue.destination as! UINavigationController).viewControllers.first as! ConfigurationEditorViewController
            
            configurationEditorVC.configuration = configuration
            
        }
        
        if segue.identifier == "startEmulatorSegue" {
            
            // set emulator configuraion
            let configuration = self.fetchedResultsController?.object(at: self.tableView.indexPath(for: sender as! UITableViewCell)!) as! Configuration
            
            (segue.destination as! EmulatorViewController).configuration = configuration
        }
    }
}
