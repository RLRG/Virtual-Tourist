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
        
        // Setting the OK navigation item
        self.navigationItem.leftBarButtonItem = UIBarButtonItem (title: "Back", style: UIBarButtonItemStyle.plain, target: self, action: #selector(PhotoAlbumViewController.backButton))
        
        // Network request to get the images when opening this new screen.
        newCollectionButton.isEnabled = false
        getImages()
        
        // TODO: Distinguish between the new pins and the ones that already have data. When it's new, we'll have to fill the CoreData DB and when the CoreData DB has data, we'll have to display the images stored there.
    }
    
    override func viewDidLayoutSubviews() {
        var error: NSError?
        do {
            try fetchedResultsController.performFetch()
        } catch let error1 as NSError {
            error = error1
            print(error!)
        }
        // Center map with the corresponding values (taking into account the zoom too).
        centerMap()
        
        // Getting the images of the pin
        // TODO: Distinguish between the new pins and the ones that already have data. When it's new, we'll have to fill the CoreData DB and when the CoreData DB has data, we'll have to display the images stored there.
        getImagesForPin()
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
    
    // MARK: - Networking
    func getImages() {
        _ = FlickrClient.shared.searchImagesByLatLon(lat: selectedPin.latitude, lon: selectedPin.longitude) { (success, message, data) in
            if success{
                /* GUARD: Is "photos" key in our result? */
                guard let photosDictionary = data?[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                    // TODO: Manage ERROR
                    //displayError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                    print("ERROR")
                    return
                }
                print("photosDictionary: \(photosDictionary)")
                
                /* GUARD: XXXXXXXXXXXXXXXXXXXXXXXX? */
                guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] else {
                    // TODO: Manage ERROR
                    //displayError("Cannot find key '\(Constants.FlickrResponseKeys.Pages)' in \(photosDictionary)")
                    print("ERROR")
                    return
                }
                print("photosArray \(photosArray)")
                
                DispatchQueue.main.sync {
                    for photo in photosArray{
                        let photoURLString = photo[Constants.FlickrResponseKeys.MediumURL] as! String
                        let photoTitleString = photo[Constants.FlickrResponseKeys.Title] as! String
                        print(photoURLString)
                        // Creating an instance of a Photo - CoreData object.
                        _ = Photo(title: photoTitleString, url: photoURLString, localPath: "", imageBinaryData: NSData(), associatedPin: self.selectedPin, context: self.stack.context)
                    }
                    // Saving CoreData DB status.
                    self.stack.save()
                    self.newCollectionButton.isEnabled = true
                }
             
                // Updating UICollectionView.
                self.collectionView.reloadData()
            }
        }
    }
    
    // MARK: - Actions
    @IBAction func newCollectionButtonAction(_ sender: Any) {
        
        // Remove Selected Photos action
        if (selectedPhotosToDelete.count > 0) {
            // a) Remove them from the CoreData BD.
            deleteSelectedPhotos {
                // b) Update UICollectionView.
                collectionView.reloadData()
            }
        }
        // Requesting a new collection
        else {
            print("Clearing the CoreData Database before requesting more images")
            deleteAllPhotosForThisPin {
                // Network request to get the images when new collection button is tapped.
                print("Reloading the request.")
                getImages()
            }
        }
        
    }

    // MARK: - CoreData
    func getImagesForPin(){
        numberOfPhotos = (fetchedResultsController.fetchedObjects?.count)!
        for photo in fetchedResultsController.fetchedObjects as! [Photo]{
            if photo.url != nil{
                _ = FlickrClient.shared.getImage(selectedPhoto: photo, completionHandler: {(success, message, data) in
                    if success{
                        if let _ = UIImage(data: data as! Data) {
                            DispatchQueue.main.async {
                                let fileName = (photo.url! as NSString).lastPathComponent
                                let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                                let pathArray = [path, fileName]
                                let fileURL = NSURL.fileURL(withPathComponents: pathArray)!
                                FileManager.default.createFile(atPath: fileURL.path, contents: (data as! Data), attributes: nil)
                                photo.localPath = fileURL.path
                                photo.imageData = data as? NSData
                                self.stack.save()
                            }
                        }
                        else{
                            // TODO: Manage ERROR
                            //completionHandler(false, "The data was not an image.")
                        }
                    }
                    else{
                        //TODO: Handle error
                    }
                })
            }
        }
        // TODO: Doing it with each photo ? Or better when all the photos finish?
        self.numberOfPhotos = (self.fetchedResultsController.fetchedObjects?.count)!
        self.collectionView.reloadData()
    }
    
    func deleteAllPhotosForThisPin(_ completionHandler: () -> Void){
        newCollectionButton.isEnabled = false
        numberOfPhotos = 0
        for photo in fetchedResultsController.fetchedObjects as![Photo]{
            stack.context.delete(photo)
        }
        stack.save()
        collectionView.reloadData()
        completionHandler()
    }
    
    func deleteSelectedPhotos(_ completionHandler: () -> Void){
        
        for photo in selectedPhotosToDelete as [IndexPath : Photo] {
            stack.context.delete(photo.value) // CoreData
            ///////////////collectionView.deleteItems(at: [photo.key]) // CollectionView
            self.numberOfPhotos -= 1
        }
        stack.save()
        selectedPhotosToDelete.removeAll()
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
        
        if photo.localPath != nil {
            cell.activityIndicator.stopAnimating()
            cell.activityIndicator.isHidden = true
            if let binaryData = photo.imageData {
                cell.image.image = UIImage(data: binaryData as Data)
            }
        }
        else{
            cell.activityIndicator.startAnimating()
            cell.activityIndicator.isHidden = false
            cell.image.image = nil
        }
        
        return cell
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize{        
        let collectionViewSize = collectionView.frame.size
        return CGSize(width: collectionViewSize.width/3.25, height: collectionViewSize.height/4.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photo = fetchedResultsController.object(at: indexPath) as! Photo
        selectedPhotosToDelete[indexPath] = photo
        //collectionView.deselectItem(at: indexPath, animated: true) // TODO: Check if this line is needed or not.
        
        changeButtonAppearanceIfNeeded()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        print("Deselecting the photo at index\(indexPath)")
        selectedPhotosToDelete.removeValue(forKey: indexPath)
        changeButtonAppearanceIfNeeded()
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

