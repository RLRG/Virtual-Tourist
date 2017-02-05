//
//  TravelLocationMapViewController.swift
//  Virtual Tourist
//
//  Created by Gmv100 on 04/02/2017.
//  Copyright © 2017 GMV. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationMapViewController: UIViewController, MKMapViewDelegate {

    // MARK: Outlets & Properties
    @IBOutlet weak var mapView: MKMapView!
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    var selectedPin:Pin? = nil
    
    // MARK: Initializers
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Displaying the pins on the map
        displayPinsOnTheMap()
        
        // Configuring gesture recognizer to add a pin
        let gestureRecognizer_TapAndHold = UILongPressGestureRecognizer(target: self, action: #selector(TravelLocationMapViewController.addPinOnTheMap(_:)))
        gestureRecognizer_TapAndHold.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(gestureRecognizer_TapAndHold)
        
        
    }

    func displayPinsOnTheMap(){
        
        // The "locations" array:
        // TODO: Query to the database the stored pins and keep them in "locations" variable
        let locations = [[String:AnyObject]]()
        
        // We will create an MKPointAnnotation for each dictionary in "locations". The
        // point annotations will be stored in this array, and then provided to the map view.
        var annotations = [MKPointAnnotation]()
        
        // The "locations" array is loaded.
        for location in locations {
            
            // Notice that the float values are being used to create CLLocationDegree values.
            // This is a version of the Double type.
            let lat = CLLocationDegrees(location["lat"] as! Double)
            let long = CLLocationDegrees(location["lat"] as! Double)
            
            // The lat and long are used to create a CLLocationCoordinates2D instance.
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            // Here we create the annotation and set its coordinate, title, and subtitle properties
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = location["title"] as? String // TODO: Set the title of the pin.
            annotation.subtitle = location["subtitle"] as? String // TODO: Set the subtitle of the pin.
            
            // Finally we place the annotation in an array of annotations.
            annotations.append(annotation)
        }
        
        // When the array is complete, we add the annotations to the map.
        self.mapView.addAnnotations(annotations)
    }
    
    
    // MARK: Actions
    
    // Add the action to add a pin (Tap and hold) and store that pin in CoreData DB.
    func addPinOnTheMap(_ gestureRecognizer:UIGestureRecognizer){
        if gestureRecognizer.state == UIGestureRecognizerState.began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            
            print(["name":annotation.title,"latitude":"\(newCoordinates.latitude)","longitude":"\(newCoordinates.longitude)"])
            mapView.addAnnotation(annotation)
            
            // TODO: Store the pin data in CoreData DB.
        }
    }
    
    // TODO: Add the action to remove pins from the map (Edit button at the top and tapping on a pin means to remove that pin) and remove that pin from CoreData.
    // TODO: Persist the map information: Center, zoom level...
    
    
    // MARK: - MKMapViewDelegate
    
    // Here we create a view with a "right callout accessory view". You might choose to look into other
    // decoration alternatives. Notice the similarity between this method and the cellForRowAtIndexPath
    // method in TableViewDataSource.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    // This delegate method is implemented to respond to taps
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        // TODO: Fix the "Tap on a pin" functionality. It does not work !!
        
        selectedPin = getPinFromAnnotation(view.annotation as! MKPointAnnotation)
        performSegue(withIdentifier: Constants.SegueIdentifiers.travelViewToPhotoAlbumSegue, sender: nil)
        
        // TODO: Delete pin when it is selected if we are in "Removing mode". Idea: Including a flag to distinguish between the two operation modes.
        
    }
    
    func getPinFromAnnotation (_ annotation: MKPointAnnotation) -> Pin {
        let pin = Pin()
        pin.latitude = annotation.coordinate.latitude
        pin.longitude = annotation.coordinate.longitude
        return pin
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.SegueIdentifiers.travelViewToPhotoAlbumSegue{
            let photoAlbumVC = segue.destination as! PhotoAlbumViewController
            photoAlbumVC.selectedPin = selectedPin
        }
    }
    
    
    // MARK: Auxiliary functions
    
    // To present an error alert view
    func displayErrorAlertViewWithMessage (_ errorString: String) {
        
        let alertController = UIAlertController()
        alertController.title = "ERROR"
        alertController.message = errorString
        let okAction = UIAlertAction(title: "ok", style: UIAlertActionStyle.default) { action in
            self.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion:nil)
    }

}

