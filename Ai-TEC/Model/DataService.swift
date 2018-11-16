//
//  DataService.swift
//  Ai-Tec
//
//  Created by vMio on 11/16/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import CoreData

class DataService {
    static let shared: DataService = DataService()
    private var _arrays: [Entity]?
    var arrays: [Entity] {
        get  {
            if _arrays == nil {
                loadEntity()
            }
            return _arrays ?? []
        }
        set {
            _arrays = newValue
        }
    }
    
    private func loadEntity() {
        _arrays = []
        do {
            _arrays = try AppDelegate.context.fetch(Entity.fetchRequest()) as [Entity]
        } catch {
            let error = error as NSError
            fatalError("Unresolved error \(error), \(error.userInfo)")
        }
    }
    
    func saveData() {
        AppDelegate.saveContext()
        loadEntity()
    }
    
    func remove(at indexPath: Int) {
        guard let object = _arrays  else { return }
        AppDelegate.context.delete(object[indexPath])
    }

}
