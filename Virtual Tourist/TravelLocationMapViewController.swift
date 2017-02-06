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
    
    // TODO: Creating a new version of the model in order to remove the 'Map' entity. It is not needed because the data is stored in UserDefaults.
    
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
        // TODO: Persist zoom.
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
            annotation.title = "Title test" // TODO: Set the title of the pin.
            annotation.subtitle = "Subtitle test" // TODO: Set the subtitle of the pin.
            
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
        let pred = NSPredicate(format: "latitude = %@ and longitude = %@", argumentArray: [annotation.coordinate.latitude, annotation.coordinate.longitude])
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
        
        // It is important to include this code if we want to select this pin again.
        mapView.deselectAnnotation(view.annotation, animated: false)
        
        // Looking for the pin in CoreData.
        let pin = getPinFromAnnotation(view.annotation as! MKPointAnnotation)
        
        // Action: Tapping on a pin.
        if operationModeAddDelete { // Operation mode: "Add"
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
    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
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
