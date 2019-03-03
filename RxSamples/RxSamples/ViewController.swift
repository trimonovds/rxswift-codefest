//
//  ViewController.swift
//  RxSamples
//
//  Created by Dmitry Trimonov on 03/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import UIKit
import RxKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        SomeSampleClass.shared.doSmth()
    }


}

