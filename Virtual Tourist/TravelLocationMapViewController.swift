//
//  TravelLocationMapViewController.swift
//  Virtual Tourist
//
//  Created by Gmv100 on 04/02/2017.
//  Copyright © 2017 GMV. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationMapViewController: UIViewController, MKMapViewDelegate {

    // MARK: - Initialization
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editDoneButton: UIBarButtonItem!
    @IBOutlet weak var tapPinsToDeleteView: UIView!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    
    // MARK: Properties
    var operationModeAddDelete:Bool = true
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    var selectedPin:Pin? = nil
    var isFirstLoading: Bool = true
    
    // MARK: Lifecycle
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
    
    
    // MARK: - Map Loading & Persistence
    
    func loadMapInfoAndCenterMap() {
        
        ///////// COORDINATES //////////
        var centerCoordinate = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        
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
        
        ///////// ZOOM LEVEL //////////
        var span = MKCoordinateSpan(latitudeDelta: 0.0, longitudeDelta: 0.0)
        
        // latitudeDelta
        if UserDefaults.standard.object(forKey: Constants.MapInfo.mapZoomLatitude) != nil {
            print("LatitudeDelta already exists: \(UserDefaults.standard.double(forKey: Constants.MapInfo.mapZoomLatitude))")
            span.latitudeDelta = UserDefaults.standard.double(forKey: Constants.MapInfo.mapZoomLatitude)
        } else{
            print("Creating the UserDefaults value for latitudeDelta")
            print(mapView.region.span.latitudeDelta)
            UserDefaults.standard.set(2, forKey: Constants.MapInfo.mapZoomLatitude)
        }
        
        // longitudeDelta
        if UserDefaults.standard.object(forKey: Constants.MapInfo.mapZoomLongitude) != nil {
            print("LongitudeDelta already exists: \(UserDefaults.standard.double(forKey: Constants.MapInfo.mapZoomLongitude))")
            span.longitudeDelta = UserDefaults.standard.double(forKey: Constants.MapInfo.mapZoomLongitude)
        } else{
            print("Creating the UserDefaults value for longitudeDelta")
            print(mapView.region.span.longitudeDelta)
            UserDefaults.standard.set(mapView.region.span.longitudeDelta, forKey: Constants.MapInfo.mapZoomLongitude)
        }
        
        UserDefaults.standard.synchronize()
        
        ///////// SET REGION //////////
        // Only if there are data persisted in the app.
        if (centerCoordinate.latitude != 0.0 && centerCoordinate.longitude != 0.0 && span.latitudeDelta != 0.0 && span.longitudeDelta != 0.0) {
            let region = MKCoordinateRegion(center: centerCoordinate, span: span)
            mapView.setRegion(region, animated: true)
        }
        
    }
    
    func persistMapInfo() {
        let lat = mapView.centerCoordinate.latitude
        let lon = mapView.centerCoordinate.longitude
        let spanLat = mapView.region.span.latitudeDelta
        let spanLon = mapView.region.span.longitudeDelta
        print("Persisting map info. Lat:\(lat) , Lon:\(lon) , latDelta:\(spanLat) , lonDelta:\(spanLon)")
        UserDefaults.standard.set(lat, forKey: Constants.MapInfo.mapCenterLatitude)
        UserDefaults.standard.set(lon, forKey: Constants.MapInfo.mapCenterLongitude)
        UserDefaults.standard.set(spanLat, forKey: Constants.MapInfo.mapZoomLatitude)
        UserDefaults.standard.set(spanLon, forKey: Constants.MapInfo.mapZoomLongitude)
        UserDefaults.standard.synchronize()
    }

    func displayPinsOnTheMap(){
        
        // The "locations" array:
        let pins = getPinsFromDB()
        
        // We will create an MKPointAnnotation for each dictionary in "locations". The
        // point annotations will be stored in this array, and then provided to the map view.
        var annotations = [MKPointAnnotation]()
        
        // The "locations" array is loaded.
        for pin:Pin in pins {
            
            // Notice that the float values are being used to create CLLocationDegree values.
            // This is a version of the Double type.
            let lat = CLLocationDegrees(pin.latitude)
            let long = CLLocationDegrees(pin.longitude)
            
            // The lat and long are used to create a CLLocationCoordinates2D instance.
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            // Here we create the annotation and set its coordinate, title, and subtitle properties
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            // Finally we place the annotation in an array of annotations.
            annotations.append(annotation)
        }
        
        // When the array is complete, we add the annotations to the map.
        self.mapView.addAnnotations(annotations)
    }
    
    func getPinsFromDB() -> [Pin] {
        var pins = [Pin]()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        do {
            let results = try stack.context.fetch(fetchRequest)
            pins = results as! [Pin]
        } catch let error as NSError {
            print("An error occured accessing managed object context \(error.localizedDescription)")
        }
        return pins
    }
    
    func getPinFromAnnotation (_ annotation: MKPointAnnotation) -> Pin {
        // Fetch request looking for the corresponding Pin.
        var pins = [Pin]()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        let pred = NSPredicate(format: "latitude = %@ and longitude = %@", argumentArray: [Double(annotation.coordinate.latitude), Double(annotation.coordinate.longitude)])
        fetchRequest.predicate = pred
        do {
            let result = try stack.context.fetch(fetchRequest)
            pins = result as! [Pin]
        } catch let error as NSError {
            print("An error occured accessing managed object context \(error.localizedDescription)")
        }
        return pins[0]
    }
    
    func deleteInDB(pin: Pin) {
        stack.context.delete(pin)
        stack.save()
    }
    
    
    // MARK: - Actions
    
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
    
    // This delegate method is implemented to respond to taps on the pins.
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        // Looking for the pin in CoreData.
        let pin = getPinFromAnnotation(view.annotation as! MKPointAnnotation)
        
        // Action: Tapping on a pin.
        if operationModeAddDelete { // Operation mode: "Add"
            
            // It is important to include this code if we want to select this pin again.
            mapView.deselectAnnotation(view.annotation, animated: false)
            
            selectedPin = pin
            performSegue(withIdentifier: Constants.SegueIdentifiers.travelViewToPhotoAlbumSegue, sender: nil)
        } else { // Operation mode: "Delete"
            mapView.removeAnnotation(view.annotation!)
            deleteInDB(pin: pin)
        }
    }
    
    // It is called when the map is starting to load.
    func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
        // Start and display a spinner.
        loadingSpinner.startAnimating()
        loadingSpinner.hidesWhenStopped = true
    }
    
    // It is called when the map has finished loading.
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        // Stop and hide a spinner.
        loadingSpinner.stopAnimating()
    }
    
    
    // MARK: - Auxiliary functions
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.SegueIdentifiers.travelViewToPhotoAlbumSegue{
            let photoAlbumVC = segue.destination as! PhotoAlbumViewController
            photoAlbumVC.selectedPin = selectedPin
        }
    }
}
