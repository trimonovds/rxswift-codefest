//
//  DrawerHideBehavior.swift
//  RxSamples
//
//  Created by Dmitry Trimonov on 21/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import Foundation
import RxSwift
import CoreLocation

protocol CameraManagerOutput: AnyObject {
    var didChangeAutomaticRotationState: Observable<Bool> { get }
}

protocol LocationManagerOutput: AnyObject {
    var didUpdateSpeed: Observable<Double> { get }
}

protocol DrawerInput: AnyObject {
    func hideIfPossible()
}

class DrawerHidingBehavior {

    // MARK: - Constructors

    init(drawerInput: DrawerInput, cameraManagerOutput: CameraManagerOutput, locationManagerOutput: LocationManagerOutput) {
        self.drawerInput = drawerInput

        Observable
            .combineLatest(
                locationManagerOutput.didUpdateSpeed
                    .map { $0 > 2.5 }
                    .distinctUntilChanged(),
                cameraManagerOutput.didChangeAutomaticRotationState
                    .distinctUntilChanged()
            )
            .filter { $0.0 && $0.1 }
            .map { _ in () }
            .bind(onNext: { [weak self] in
                guard let slf = self else { return }
                slf.drawerInput.hideIfPossible()
            })
            .disposed(by: bag)
    }

    // MARK: - Private Properties

    private let drawerInput: DrawerInput
    private let bag = DisposeBag()
}
