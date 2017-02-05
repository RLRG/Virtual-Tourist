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
    @IBOutlet weak var editDoneButton: UIBarButtonItem!
    @IBOutlet weak var tapPinsToDeleteView: UIView!
    
    var operationModeAddDelete:Bool = true
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    var selectedPin:Pin? = nil
    
    
    // MARK: Initializers
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configuring gesture recognizer to add a pin
        let gestureRecognizer_TapAndHold = UILongPressGestureRecognizer(target: self, action: #selector(TravelLocationMapViewController.addPinOnTheMap(_:)))
        gestureRecognizer_TapAndHold.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(gestureRecognizer_TapAndHold)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Initializing values to be in "Add" operation mode by default.
        tapPinsToDeleteView.isHidden = true
        operationModeAddDelete = true
        
        // Initializing UI
        performUIUpdatesOnMain {
            
            // TODO: Load the map in the center and with the zoom stored in CoreData.
            // Query the CoreData DB.
            // mapView.setCenter(<#T##coordinate: CLLocationCoordinate2D##CLLocationCoordinate2D#>, animated: <#T##Bool#>)
            
            // Displaying the pins on the map
            self.displayPinsOnTheMap()
        }
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

            // Storing the pin data in CoreData DB
            _ = Pin(lat: newCoordinates.latitude, lon: newCoordinates.longitude, context: stack.context)
        }
    }
    
    // TODO: Persist the map information: Center, zoom level...
    func persistMapInfo() {
        // mapView.centerCoordinate.latitude
        // mapView.centerCoordinate.longitude
        // TODO: How do I get the zoom level of the map?
    }
    
    // This action is used in order to switch between the two operation modes of the screen:
    // 1- Add pins / 2- Delete pins.
    @IBAction func editDoneButton(_ sender: Any) {
        
        if (operationModeAddDelete == true) {
            operationModeAddDelete = false
            performUIUpdatesOnMain {
                self.editDoneButton.title = "Done"
                self.tapPinsToDeleteView.isHidden = false
            }
        }else {
            operationModeAddDelete = true
            performUIUpdatesOnMain {
                self.editDoneButton.title = "Edit"
                self.tapPinsToDeleteView.isHidden = true
            }
        }
    }
    
    
    
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
        // Action: Tapping on a pin.
        if operationModeAddDelete { // Operation mode: "Add"
            selectedPin = getPinFromAnnotation(view.annotation as! MKPointAnnotation)
            performSegue(withIdentifier: Constants.SegueIdentifiers.travelViewToPhotoAlbumSegue, sender: nil)
        } else { // Operation mode: "Delete"
            // TODO: Delete pin when it is selected if we are in "Removing mode".
        }
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

