//
//  Pin+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Gmv100 on 05/02/2017.
//  Copyright © 2017 GMV. All rights reserved.
//

import Foundation
import CoreData


public class Pin: NSManagedObject {

    convenience init(lat latitude: Double, lon longitude: Double, context: NSManagedObjectContext) {
    
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: ent, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
}
