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
    
    // MARK - Outlets & Properties
    @IBOutlet weak var mapViewPhotoAlbum: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var selectedPin:Pin!
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    var numberOfPhotos = 0
    
    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "pin == %@", argumentArray: [self.selectedPin])
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.stack.context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    // MARK - Initializers
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Setting delegates and data sources
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        // Setting the OK navigation item
        self.navigationItem.leftBarButtonItem = UIBarButtonItem (title: "OK", style: UIBarButtonItemStyle.plain, target: self, action: #selector(PhotoAlbumViewController.backButton))
        
        // Network request to get the images when opening this new screen.
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
        getImagesForPin()
        
        // TODO: Fix the OK button to be displayed with the back icon.
    }
    
    func centerMap(){
        let lat = CLLocationDegrees(selectedPin.latitude)
        let long = CLLocationDegrees(selectedPin.longitude)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Title test" // TODO: Set the title of the pin.
        annotation.subtitle = "Subtitle test" // TODO: Set the subtitle of the pin.
        mapViewPhotoAlbum.addAnnotation(annotation)
        mapViewPhotoAlbum.isUserInteractionEnabled = false
        mapViewPhotoAlbum.isScrollEnabled = false
        mapViewPhotoAlbum.isZoomEnabled = false
        
        let span = MKCoordinateSpan(latitudeDelta: mapViewPhotoAlbum.region.span.latitudeDelta / 2, longitudeDelta: mapViewPhotoAlbum.region.span.latitudeDelta  / 2)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapViewPhotoAlbum.setRegion(region, animated: false)
    }
    
    // MARK: Navigation
    func backButton (){
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: true)
        }
    }
    
    // MARK - Networking
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
                
                /* GUARD: Is "pages" key in the photosDictionary? */
                guard let totalPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                    // TODO: Manage ERROR
                    //displayError("Cannot find key '\(Constants.FlickrResponseKeys.Pages)' in \(photosDictionary)")
                    print("ERROR")
                    return
                }
                
                // TODO: Manage response of the Web Service.
                print("Total pages: \(totalPages)")
                print("TODO: Manage response of the Web Service.")
                // TODO: pick a random page!
                //let pageLimit = min(totalPages, 40)
                //let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                //self.displayImageFromFlickrBySearch(methodParameters, withPageNumber: randomPage)
                
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
                        let photoURLString = photo["url_m"] as! String
                        print(photoURLString)
                        // TODO: Creating an instance of a Photo - CoreData object.
                        _ = Photo(title: "PHOTO TITLE", url: photoURLString, localPath: "", imageBinaryData: NSData(), associatedPin: self.selectedPin, context: self.stack.context) // TODO: Title of the photo, localPath?, imageBinaryData?
                    }
                    // Saving CoreData DB status.
                    self.stack.save()
                }
            }
        }
    }
    
    // MARK - Actions
    @IBAction func newCollectionButtonAction(_ sender: Any) {
        // Network request to get the images when new collection button is tapped.
        print("Reloading the request.")
        getImages()
    }
    
    // TODO: Enable New Collection button when the result of the request has arrived and disable button when the request is still loading.
    // TODO: Select a photo (or several photos) and display the button "Remove Selected Pictures".
    // TODO: Remove selected pictures action. a) Remove them from the CoreData BD, b) Update UICollectionView.
    
    // MARK - CoreData
    
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
            cell.image.image = UIImage(data: photo.imageData! as Data)
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
        let lineWidth: CGFloat = 10.0
        let numberOfLines: CGFloat = 2.0
        let numberOfCellsInOneLine: CGFloat = 3.0
        let widthWithAdjustment = (view.frame.width) - (lineWidth * numberOfLines)
        return CGSize(width: widthWithAdjustment/numberOfCellsInOneLine, height: widthWithAdjustment/numberOfCellsInOneLine)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photo = fetchedResultsController.object(at: indexPath) as! Photo
        collectionView.deselectItem(at: indexPath, animated: true)
        stack.context.delete(photo)
        numberOfPhotos -= 1
        print("Deleting indexPath: section: \(indexPath.section), item: \(indexPath.item)")
        collectionView.deleteItems(at: [indexPath])
        stack.save()
    }
}

