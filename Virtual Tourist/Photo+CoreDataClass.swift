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

    convenience init(title photoTitle: String, url photoUrl: String, containsImage itContainsImage: Bool, imageBinaryData imageData:NSData?, associatedPin pin: Pin, context: NSManagedObjectContext) {
        
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: ent, insertInto: context)
            self.title = photoTitle
            self.url = photoUrl
            self.containsImage = itContainsImage
            self.imageData = imageData
            self.pin = pin
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
}
