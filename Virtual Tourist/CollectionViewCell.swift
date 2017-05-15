//
//  CollectionViewCell.swift
//  Virtual Tourist
//
//  Created by RLRG on 15/05/2017.
//  Copyright © 2017 GMV. All rights reserved.
//

import Foundation
import UIKit

class CollectionViewCell: UICollectionViewCell{
    
    @IBOutlet var image: UIImageView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    override func prepareForReuse() {
        if image.image == nil{
            activityIndicator.startAnimating()
        }
        else{
            activityIndicator.stopAnimating()
        }
    }
}