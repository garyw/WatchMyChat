//
//  ViewController.swift
//  WatchMyChat
//
//  Created by Gary Waliczek on 2/5/18.
//  Copyright © 2018 Gary Waliczek. All rights reserved.
//

import UIKit
import OAuthSwift

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool)
    {
        MixerRest.oauthUxParent = self
        _ = MixerRest.client()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        MixerRest.oauthUxParent = nil
    }
}

