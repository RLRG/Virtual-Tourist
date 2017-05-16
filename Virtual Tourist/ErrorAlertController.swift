//
//  ErrorAlertController.swift
//  Virtual Tourist
//
//  Created by RLRG on 16/05/2017.
//  Copyright © 2017 GMV. All rights reserved.
//

import Foundation
import UIKit

class ErrorAlertController {
    
    // To present an error alert view
    class func displayErrorAlertViewWithMessage (_ errorString: String, caller viewController: UIViewController) {
        
        print("ErrorAlertController - displayErrorAlertViewWithMessage: \(errorString)")
        
        let alertController = UIAlertController()
        alertController.title = "ERROR"
        alertController.message = errorString
        let okAction = UIAlertAction(title: "ok", style: UIAlertActionStyle.default) { action in
            viewController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(okAction)
        viewController.present(alertController, animated: true, completion:nil)
    }
    
}
