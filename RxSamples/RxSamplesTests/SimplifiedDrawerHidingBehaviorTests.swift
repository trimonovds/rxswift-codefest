//
//  SimplifiedDrawerHidingBehaviorTests.swift
//  RxSamplesTests
//
//  Created by Dmitry Trimonov on 21/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import Foundation
import XCTest
import RxSwift
import RxTest
@testable import RxSamples

class SimplifiedDrawerHidingBehaviorTests: XCTestCase {

    var testScheduler: TestScheduler!

    override func setUp() {
        super.setUp()
        testScheduler = TestScheduler(initialClock: 0)
    }

    func makeSut(didChangeAutomaticRotationStateEvents: [Recorded<Event<Bool>>],
                 didUpdateSpeedEvents: [Recorded<Event<Double>>],
                 onScheduler testScheduler: TestScheduler) -> Observable<Void>
    {
        let didChangeAutomaticRotationState = testScheduler.createHotObservable(didChangeAutomaticRotationStateEvents)
        let didUpdateSpeed = testScheduler.createHotObservable(didUpdateSpeedEvents)
        return SimplifiedDrawerHidingBehavior.make(
            didChangeAutomaticRotationState: didChangeAutomaticRotationState.asObservable(),
            didUpdateSpeed: didUpdateSpeed.asObservable()
        )
    }

    // Observable sequence will be:
    // * created at virtual time `Defaults.created`           -> 100
    // * subscribed to at virtual time `Defaults.subscribed`  -> 200
    // * subscription will be disposed at `Defaults.disposed` -> 1000
    func testWhenSpeedExceedsLimitAndAutoRotationIsOnThenDrawerHides_UsingStartWithDefaults() {
        let didChangeAutomaticRotationStateEvents: [Recorded<Event<Bool>>] = [
            .next(300, false),
            .next(600, true)
        ]

        let didUpdateSpeedEvents: [Recorded<Event<Double>>] = [
            .next(400, 1.5),
            .next(700, 2.0),
            .next(800, 2.51), // Exceeds
        ]

        let hidesObserver = testScheduler.start { () -> Observable<Void> in
            return self.makeSut(
                didChangeAutomaticRotationStateEvents: didChangeAutomaticRotationStateEvents,
                didUpdateSpeedEvents: didUpdateSpeedEvents,
                onScheduler: self.testScheduler
            )
        }

        XCTAssert(hidesObserver.events.count == 1)
        XCTAssert(hidesObserver.events[0].time == 800)
    }
}
