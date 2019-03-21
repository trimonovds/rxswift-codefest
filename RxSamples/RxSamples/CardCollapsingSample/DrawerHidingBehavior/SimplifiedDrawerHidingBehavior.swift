//
//  SimplifiedDrawerHidingBehavior.swift
//  RxSamples
//
//  Created by Dmitry Trimonov on 21/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import Foundation
import RxSwift

class SimplifiedDrawerHidingBehavior {
    static func make(didChangeAutomaticRotationState: Observable<Bool>, didUpdateSpeed: Observable<Double>) -> Observable<Void> {
        return Observable
            .combineLatest(
                didUpdateSpeed
                    .map { $0 > 2.5 }
                    .distinctUntilChanged(),
                didChangeAutomaticRotationState
                    .distinctUntilChanged()
            )
            .filter { $0.0 && $0.1 }
            .map { _ in () }
    }
}
