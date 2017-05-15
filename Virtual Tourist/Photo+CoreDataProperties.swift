//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by RLRG on 15/05/2017.
//  Copyright © 2017 GMV. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var title: String?
    @NSManaged public var url: String?
    @NSManaged public var localPath: String?
    @NSManaged public var imageData: NSData?
    @NSManaged public var pin: Pin?

}
