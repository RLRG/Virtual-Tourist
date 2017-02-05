//
//  Photo+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Gmv100 on 05/02/2017.
//  Copyright © 2017 GMV. All rights reserved.
//

import Foundation
import CoreData


public class Photo: NSManagedObject {

    convenience init(title photoTitle: String, url photoUrl: String, context: NSManagedObjectContext) {
        
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: ent, insertInto: context)
            self.title = photoTitle
            self.url = photoUrl
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
}
