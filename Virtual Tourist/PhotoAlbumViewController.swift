//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Gmv100 on 04/02/2017.
//  Copyright © 2017 GMV. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController : UIViewController, MKMapViewDelegate {
    
    // MARK: Outlets & Properties
    @IBOutlet weak var mapViewPhotoAlbum: MKMapView!
    var selectedPin:Pin!
    
    // MARK: Initializers
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Setting the OK navigation item
        self.navigationItem.leftBarButtonItem = UIBarButtonItem (title: "OK", style: UIBarButtonItemStyle.plain, target: self, action: #selector(PhotoAlbumViewController.backButton))
        
        // TODO: Configure Flickr.
        // TODO: Create the network request to get the images when opening this new screen.
        
        
    }
    
    // MARK: Navigation
    func backButton (){
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: true)
        }
    }
    
    // MARK: Actions
    
    // TODO: New Collection button action (reload the request).
    // TODO: Enable New Collection button when the result of the request has arrived and disable button when the request is still loading.
    // TODO: Select a photo (or several photos) and display the button "Remove Selected Pictures".
    // TODO: Remove selected pictures action. a) Remove them from the CoreData BD, b) Update UICollectionView.
    
}
