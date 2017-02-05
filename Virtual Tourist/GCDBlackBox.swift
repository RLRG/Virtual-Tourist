//
//  GCDBlackBox.swift
//  Virtual Tourist
//
//  Created by Gmv100 on 05/02/2017.
//  Copyright © 2017 GMV. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
