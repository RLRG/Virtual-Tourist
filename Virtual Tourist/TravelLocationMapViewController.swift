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
    
    var isFirstLoading: Bool = true
    
    // TODO: Add a loading spinner while the map is loading.
    // TODO: Creating a new version of the model in order to remove the 'Map' entity. It is not needed because the data is stored in UserDefaults.
    
    // MARK: Initializers
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setting the delegate of the mapView to this viewController
        mapView.delegate = self
        
        // Configuring gesture recognizer to add a pin
        let gestureRecognizer_TapAndHold = UILongPressGestureRecognizer(target: self, action: #selector(TravelLocationMapViewController.addPinOnTheMap(_:)))
        gestureRecognizer_TapAndHold.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(gestureRecognizer_TapAndHold)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Initializing values to be in "Add" operation mode by default and to center the map appropriately
        isFirstLoading = true
        tapPinsToDeleteView.isHidden = true
        operationModeAddDelete = true
        
        // Initializing UI
        performUIUpdatesOnMain {
            // Load the map in the center and with the zoom stored.
            self.loadMapInfoAndCenterMap()
            
            // Displaying the pins on the map.
            self.displayPinsOnTheMap()
        }
    }
    
    
    // MARK: Map Loading & Persistence
    
    func loadMapInfoAndCenterMap() {
        
        var centerCoordinate = CLLocationCoordinate2D()
        
        // latitude
        if UserDefaults.standard.object(forKey: Constants.MapInfo.mapCenterLatitude) != nil {
            print("Latitude already exists: \(UserDefaults.standard.double(forKey: Constants.MapInfo.mapCenterLatitude))")
            centerCoordinate.latitude = UserDefaults.standard.double(forKey: Constants.MapInfo.mapCenterLatitude)
        } else{
            print("Creating the UserDefaults value for latitude")
            UserDefaults.standard.set(mapView.centerCoordinate.latitude, forKey: Constants.MapInfo.mapCenterLatitude)
        }
        
        // longitude
        if UserDefaults.standard.object(forKey: Constants.MapInfo.mapCenterLongitude) != nil {
            print("Longitude already exists: \(UserDefaults.standard.double(forKey: Constants.MapInfo.mapCenterLongitude))")
            centerCoordinate.longitude = UserDefaults.standard.double(forKey: Constants.MapInfo.mapCenterLongitude)
        } else{
            print("Creating the UserDefaults value for longitude")
            UserDefaults.standard.set(mapView.centerCoordinate.longitude, forKey: Constants.MapInfo.mapCenterLongitude)
        }
        
        // TODO: Zoom. How do I get the zoom level of the map? Getting the span of the surrounding area displayed (MKCoordinateRegionMakeWithDistance, mapView.setRegion)
        
        UserDefaults.standard.synchronize()
        mapView.setCenter(centerCoordinate, animated: true)
        
    }
    
    func persistMapInfo() {
        let lat = mapView.centerCoordinate.latitude
        let lon = mapView.centerCoordinate.longitude
        print("Persisting map info. Lat:\(lat) , Lon:\(lon)")
        UserDefaults.standard.set(lat, forKey: Constants.MapInfo.mapCenterLatitude)
        UserDefaults.standard.set(lon, forKey: Constants.MapInfo.mapCenterLongitude)
        // TODO: Zoom.
        UserDefaults.standard.synchronize()
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
            stack.save()
        }
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
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    // This function tells the delegate that the region displayed of the map has changed
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if isFirstLoading {
            isFirstLoading = false
        } else {
            persistMapInfo()
        }
    }
    
    // This delegate method is implemented to respond to taps
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        // It is important to include this code if we want to select this pin again.
        mapView.deselectAnnotation(view.annotation, animated: false)
        
        // TODO: Fix the "Tap on a pin" functionality. It does not work !!
        // Action: Tapping on a pin.
        if operationModeAddDelete { // Operation mode: "Add"
            selectedPin = getPinFromAnnotation(view.annotation as! MKPointAnnotation)
            performSegue(withIdentifier: Constants.SegueIdentifiers.travelViewToPhotoAlbumSegue, sender: nil)
        } else { // Operation mode: "Delete"
            mapView.removeAnnotation(view.annotation!)
            // TODO: Delete pin when it is selected if we are in "Removing mode" (CoreData)
            // stack.context.delete(getPinFromAnnotation(view.annotation! as! MKPointAnnotation))
        }
    }
    
    func getPinFromAnnotation (_ annotation: MKPointAnnotation) -> Pin {
        // TODO: Fetch request looking for the corresponding Pin. For now, we create a new pin object in CoreData.
        let pin = Pin(lat: annotation.coordinate.latitude, lon: annotation.coordinate.longitude, context: stack.context)
        return pin
    }
    
    // It is called when the map is starting to load.
    func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
        // TODO: Include the code to start and display a spinner.
    }
    
    // It is called when the map has finished loading.
    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        // TODO: Include the code to stop and hide a spinner.
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

