//
//  Map+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Gmv100 on 05/02/2017.
//  Copyright © 2017 GMV. All rights reserved.
//

import Foundation
import CoreData


extension Map {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Map> {
        return NSFetchRequest<Map>(entityName: "Map");
    }

    @NSManaged public var centerLatitude: Double
    @NSManaged public var centerLongitude: Double
    @NSManaged public var zoomLevel: Double
    @NSManaged public var pins: NSSet?

}

// MARK: Generated accessors for pins
extension Map {

    @objc(addPinsObject:)
    @NSManaged public func addToPins(_ value: Pin)

    @objc(removePinsObject:)
    @NSManaged public func removeFromPins(_ value: Pin)

    @objc(addPins:)
    @NSManaged public func addToPins(_ values: NSSet)

    @objc(removePins:)
    @NSManaged public func removeFromPins(_ values: NSSet)

}
