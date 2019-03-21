//
//  Adapters.swift
//  RxSamples
//
//  Created by Dmitry Trimonov on 21/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import Foundation
import Utils
import CoreLocation
import UltraDrawerView
import RxSwift
import RxCocoa

class FakeLocationManagerOutput: LocationManagerOutput {
    let speed = BehaviorRelay<Double>(value: 0)

    var didUpdateSpeed: Observable<Double> {
        return speed.asObservable().debug("Speed", trimOutput: false)
    }
}

class FakeCameraManagerOutput: CameraManagerOutput {

    let isOn = BehaviorRelay<Bool>(value: false)

    var didChangeAutomaticRotationState: Observable<Bool> {
        return isOn.asObservable().debug("AutomaticRotation isOn", trimOutput: false)
    }
}

extension DrawerView: DrawerInput {
    func hideIfPossible() {
        self.setState(.bottom, animated: true)
    }
}
