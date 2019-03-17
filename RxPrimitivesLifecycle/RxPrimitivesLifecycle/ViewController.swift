//
//  ViewController.swift
//  RxPrimitivesLifecycle
//
//  Created by Dmitry Trimonov on 17/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        active.accept(true)
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        active.accept(false)
    }
    private let active = BehaviorRelay<Bool>(value: false)
}

