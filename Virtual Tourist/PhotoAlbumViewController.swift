//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Gmv100 on 04/02/2017.
//  Copyright © 2017 GMV. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController : UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    // MARK: - Outlets & Properties
    @IBOutlet weak var mapViewPhotoAlbum: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    var selectedPin:Pin!
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    var numberOfPhotos = 0
    var firstTimeViewDidLayoutSubviewsIsCalled = true
    
    var selectedPhotosToDelete = [IndexPath: Photo]()
    
    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "pin == %@", argumentArray: [self.selectedPin])
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.stack.context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    // MARK: - Initializers
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Setting delegates and data sources
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        // Allowing multiple selection property
        self.collectionView.allowsMultipleSelection = true
        
        // Setting the OK navigation item
        self.navigationItem.leftBarButtonItem = UIBarButtonItem (title: "Back", style: UIBarButtonItemStyle.plain, target: self, action: #selector(PhotoAlbumViewController.backButton))
        
        // Flag
        firstTimeViewDidLayoutSubviewsIsCalled = true
    }
    
    override func viewDidLayoutSubviews() {
        var error: NSError?
        do {
            try fetchedResultsController.performFetch()
        } catch let error1 as NSError {
            error = error1
            print(error!)
        }
        
        // Updating the number of items.
        numberOfPhotos = (fetchedResultsController.fetchedObjects?.count)!
        
        // Center map with the corresponding values (taking into account the zoom too).
        centerMap()
        
        // Getting the images of the pin
        if (firstTimeViewDidLayoutSubviewsIsCalled) {
            firstTimeViewDidLayoutSubviewsIsCalled = false
            if (numberOfPhotos == 0) {
                // Network request to get the images when opening this new screen.
                newCollectionButton.isEnabled = false
                getImagesURLs()
            } else {
                newCollectionButton.isEnabled = true
            }
        }
    }
    
    func centerMap(){
        ///////// COORDINATES //////////
        let lat = CLLocationDegrees(selectedPin.latitude)
        let long = CLLocationDegrees(selectedPin.longitude)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapViewPhotoAlbum.addAnnotation(annotation)
        
        ///////// ZOOM LEVEL //////////
        var span = MKCoordinateSpan()
        // latitudeDelta
        if UserDefaults.standard.object(forKey: Constants.MapInfo.mapZoomLatitude) != nil {
            span.latitudeDelta = UserDefaults.standard.double(forKey: Constants.MapInfo.mapZoomLatitude)
        } else{
            print("Error: LatitudeDelta must exist at this point.")
        }
        // longitudeDelta
        if UserDefaults.standard.object(forKey: Constants.MapInfo.mapZoomLongitude) != nil {
            span.longitudeDelta = UserDefaults.standard.double(forKey: Constants.MapInfo.mapZoomLongitude)
        } else{
            print("Error: LongitudeDelta must exist at this point.")
        }
        
        ///////// SET REGION //////////
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapViewPhotoAlbum.setRegion(region, animated: false)
        mapViewPhotoAlbum.isUserInteractionEnabled = false
        mapViewPhotoAlbum.isScrollEnabled = false
        mapViewPhotoAlbum.isZoomEnabled = false
    }
    
    // MARK: - Navigation
    func backButton (){
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: true)
        }
    }
    
    // MARK: - Actions
    @IBAction func newCollectionButtonAction(_ sender: Any) {
        
        // Remove Selected Photos action
        if (selectedPhotosToDelete.count > 0) {
            // a) Remove them from the CoreData BD.
            deleteSelectedPhotos {
                // b) Refreshing the CoreData query and updating the number of items in the collection view.
                var error: NSError?
                do {
                    try fetchedResultsController.performFetch()
                } catch let error1 as NSError {
                    error = error1
                    print(error!)
                }
                numberOfPhotos = (fetchedResultsController.fetchedObjects?.count)!
                
                // c) Update UICollectionView
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    self.changeButtonAppearanceIfNeeded()
                }
            }
        }
            // Requesting a new collection
        else {
            print("Clearing the CoreData Database before requesting more images")
            deleteAllPhotosForThisPin {
                // Network request to get the images when new collection button is tapped.
                print("Reloading the request.")
                getImagesURLs()
            }
        }
        
    }
    
    // MARK: - Networking & CoreData
    func getImagesURLs() {
        _ = FlickrClient.shared.searchImagesByLatLon(lat: selectedPin.latitude, lon: selectedPin.longitude) { (success, message, data) in
            if success{
                /* GUARD: Is "photos" key in our result? */
                guard let photosDictionary = data?[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                    ErrorAlertController.displayErrorAlertViewWithMessage("There are no photos returned in the response (photos dict)", caller: self)
                    return
                }
                print("photosDictionary: \(photosDictionary)")
                
                /* GUARD: Is "photo" key in our result?? */
                guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] else {
                    ErrorAlertController.displayErrorAlertViewWithMessage("There are no photos returned in the response (photos array)", caller: self)
                    return
                }
                print("photosArray \(photosArray)")
                
                DispatchQueue.main.sync {
                    for photo in photosArray{
                        let photoURLString = photo[Constants.FlickrResponseKeys.MediumURL] as! String
                        let photoTitleString = photo[Constants.FlickrResponseKeys.Title] as! String
                        print(photoURLString)
                        // Creating an instance of a Photo - CoreData object.
                        _ = Photo(title: photoTitleString, url: photoURLString, containsImage: false, imageBinaryData: nil, associatedPin: self.selectedPin, context: self.stack.context)
                    }
                    
                    // Saving CoreData DB status.
                    self.stack.save()
                    self.newCollectionButton.isEnabled = true
                    
                    // Requesting the image binary data.
                    self.getImagesForPin()
                }
            } else {
                ErrorAlertController.displayErrorAlertViewWithMessage(message ?? "The request was not successful. Try again! ", caller: self)
            }
        }
    }
    
    func getImagesForPin(){
        
        var error: NSError?
        do {
            try fetchedResultsController.performFetch()
        } catch let error1 as NSError {
            error = error1
            print(error!)
        }
        numberOfPhotos = (fetchedResultsController.fetchedObjects?.count)!
        
        // Updating collectionView (with this reload, what we get is to display the spinners loading until the image is get from the networking request).
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        
        for photo in fetchedResultsController.fetchedObjects as! [Photo]{
            if photo.url != nil {
                _ = FlickrClient.shared.getImage(selectedPhoto: photo, completionHandler: {(success, message, data) in
                    if success{
                        if let _ = UIImage(data: data as! Data) {
                            DispatchQueue.main.async {
                                photo.imageData = data as? NSData
                                photo.containsImage = true
                                self.stack.save()
                            }
                        }
                        else{
                            print("The data of the image couldn't be persisted.")
                        }
                    }
                    else{
                        print(message ?? "The data of the image couldn't be persisted.")
                    }
                    
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                })
            }
        }
    }
    
    func deleteAllPhotosForThisPin(_ completionHandler: () -> Void){
        newCollectionButton.isEnabled = false
        numberOfPhotos = 0
        for photo in fetchedResultsController.fetchedObjects as![Photo]{
            stack.context.delete(photo)
        }
        stack.save()
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        
        completionHandler()
    }
    
    func deleteSelectedPhotos(_ completionHandler: () -> Void){
        
        for photo in selectedPhotosToDelete as [IndexPath : Photo] {
            stack.context.delete(photo.value) // CoreData
            self.numberOfPhotos -= 1
        }
        stack.save()
        selectedPhotosToDelete.removeAll()
        completionHandler()
    }
}


extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if numberOfPhotos > 0 {
            return numberOfPhotos
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionViewCell", for: indexPath) as! CollectionViewCell
        let photo = fetchedResultsController.object(at: indexPath) as! Photo
        
        if photo.containsImage {
            cell.activityIndicator.stopAnimating()
            cell.activityIndicator.isHidden = true
            if let binaryData = photo.imageData {
                cell.image.image = UIImage(data: binaryData as Data)
                
                if (cell.isSelected) {
                    cell.image.alpha = 0.25
                } else {
                    cell.image.alpha = 1
                }
            }
        }
        else{
            cell.activityIndicator.startAnimating()
            cell.activityIndicator.isHidden = false
            cell.image.image = nil
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize{        
        let collectionViewSize = collectionView.frame.size
        return CGSize(width: collectionViewSize.width/3.25, height: collectionViewSize.height/4.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Selecting the photo at index\(indexPath)")
        let photo = fetchedResultsController.object(at: indexPath) as! Photo
        selectedPhotosToDelete[indexPath] = photo
        changeButtonAppearanceIfNeeded()
        
        // Changing the cell representation
        let cell = collectionView.cellForItem(at: indexPath) as! CollectionViewCell
        cell.image.alpha = 0.25
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        print("Deselecting the photo at index\(indexPath)")
        selectedPhotosToDelete.removeValue(forKey: indexPath)
        changeButtonAppearanceIfNeeded()
        
        // Changing the cell representation
        let cell = collectionView.cellForItem(at: indexPath) as! CollectionViewCell
        cell.image.alpha = 1
    }
    
    func changeButtonAppearanceIfNeeded()
    {
        if (selectedPhotosToDelete.count > 0 && self.newCollectionButton.titleLabel?.text != "Remove Selected Photos") {
            DispatchQueue.main.async {
                self.newCollectionButton.setTitle("Remove Selected Photos", for: UIControlState.normal)
                self.newCollectionButton.sizeToFit()
            }
        } else if (selectedPhotosToDelete.count == 0 && self.newCollectionButton.titleLabel?.text != "New Collection") {
            DispatchQueue.main.async {
                self.newCollectionButton.setTitle("New Collection", for: UIControlState.normal)
                self.newCollectionButton.sizeToFit()
            }
        }
    }
}

