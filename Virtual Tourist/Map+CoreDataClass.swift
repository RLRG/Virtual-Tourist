//
//  Map+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Gmv100 on 05/02/2017.
//  Copyright © 2017 GMV. All rights reserved.
//

import Foundation
import CoreData


public class Map: NSManagedObject {

    convenience init(lat latitude: Double, lon longitude: Double, zoom zoomLevel: Double, context: NSManagedObjectContext) {
        
        if let ent = NSEntityDescription.entity(forEntityName: "Map", in: context) {
            self.init(entity: ent, insertInto: context)
            self.centerLatitude = latitude
            self.centerLongitude = longitude
            self.zoomLevel = zoomLevel
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
}
