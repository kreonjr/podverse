//
//  UIViewController+InternetNeededAlert.swift
//  podverse
//
//  Created by Mitchell Downey on 6/4/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit

extension UIViewController {
    func showInternetNeededAlert(message: String) {
        let internetNeededAlert = PVReachability.manager.createInternetConnectionNeededAlert(message)
        presentViewController(internetNeededAlert, animated: true, completion: nil)
    }
}


