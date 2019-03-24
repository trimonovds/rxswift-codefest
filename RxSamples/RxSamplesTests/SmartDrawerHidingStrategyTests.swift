//
//  SmartDrawerHidingBehaviorTests.swift
//  RxSamplesTests
//
//  Created by Dmitry Trimonov on 23/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import Foundation
import XCTest
import RxSwift
import RxTest
import RxCocoa
@testable import RxSamples

class SmartDrawerHidingStrategyTests: XCTestCase {

    var testScheduler: TestScheduler!

    override func setUp() {
        super.setUp()
        testScheduler = TestScheduler(initialClock: 0)
    }

    func makeSut(didChangeAutoRotationModeEvents: [Recorded<Event<Bool>>],
                 didUpdateSpeedEvents: [Recorded<Event<Double>>],
                 onScheduler testScheduler: TestScheduler) -> Observable<Void>
    {
        let didChangeAutoRotationMode = testScheduler.createHotObservable(didChangeAutoRotationModeEvents)
        let didUpdateSpeed = testScheduler.createHotObservable(didUpdateSpeedEvents)
        return SmartDrawerHidingStrategy(timerScheduler: testScheduler, timeIntervalInSeconds: 5).hideEvents(
            didChangeAutoRotationMode: didChangeAutoRotationMode.asObservable(),
            didUpdateSpeed: didUpdateSpeed.asObservable()
        )
    }

    func testWhenSpeedExceedsThresholdWhileAutoRotationIsOnThenDrawerHidesIn5SecIfNoSpeedFallsAndAutorotationTurnOffs() {
        let didChangeAutoRotationModeEvents: [Recorded<Event<Bool>>] = [
            .next(300, false),
            .next(600, true)
        ]

        let didUpdateSpeedEvents: [Recorded<Event<Double>>] = [
            .next(400, 1.5),
            .next(700, 2.0),
            .next(800, 2.51), // Speed exceeds threshold
        ]

        let hidesObserver = testScheduler.start { () -> Observable<Void> in
            return self.makeSut(
                didChangeAutoRotationModeEvents: didChangeAutoRotationModeEvents,
                didUpdateSpeedEvents: didUpdateSpeedEvents,
                onScheduler: self.testScheduler
            )
        }

        XCTAssert(hidesObserver.events.count == 1)
        XCTAssert(hidesObserver.events[0].time == 805)
    }

    func testWhenSpeedExceedsThresholdWhileAutoRotationIsOnThenIfSpeedFallsBelowThresholdIn5SecIntervalThenDrawerDoesntHide() {
        let didChangeAutoRotationModeEvents: [Recorded<Event<Bool>>] = [
            .next(300, false),
            .next(600, true)
        ]

        let didUpdateSpeedEvents: [Recorded<Event<Double>>] = [
            .next(400, 1.5),
            .next(700, 2.0),
            .next(800, 2.51), // Speed exceeds threshold
            .next(804, 2.49), // Speed falls below threshold in 5 sec interval (started at 800)
        ]

        let hidesObserver = testScheduler.start { () -> Observable<Void> in
            return self.makeSut(
                didChangeAutoRotationModeEvents: didChangeAutoRotationModeEvents,
                didUpdateSpeedEvents: didUpdateSpeedEvents,
                onScheduler: self.testScheduler
            )
        }

        XCTAssert(hidesObserver.events.isEmpty)
    }

    func testWhenSpeedExceedsThresholdWhileAutoRotationIsOnThenIfAutorotationTurnsOffIn5SecIntervalThenDrawerDoesntHide() {
        let didChangeAutoRotationModeEvents: [Recorded<Event<Bool>>] = [
            .next(300, false),
            .next(600, true),
            .next(804, false) // Autorotation turns off in 5 sec interval (started at 800)
        ]

        let didUpdateSpeedEvents: [Recorded<Event<Double>>] = [
            .next(400, 1.5),
            .next(700, 2.0),
            .next(800, 2.51), // Speed exceeds threshold
        ]

        let hidesObserver = testScheduler.start { () -> Observable<Void> in
            return self.makeSut(
                didChangeAutoRotationModeEvents: didChangeAutoRotationModeEvents,
                didUpdateSpeedEvents: didUpdateSpeedEvents,
                onScheduler: self.testScheduler
            )
        }

        XCTAssert(hidesObserver.events.isEmpty)
    }

    func testWhenAutoRotationTurnsOnWhileSpeedIsMoreThanThresholdThenDrawerHides() {
        let didChangeAutoRotationModeEvents: [Recorded<Event<Bool>>] = [
            .next(300, false),
            .next(900, true)
        ]

        let didUpdateSpeedEvents: [Recorded<Event<Double>>] = [
            .next(400, 1.5),
            .next(700, 2.0),
            .next(800, 2.51), // Exceeds
        ]

        let hidesObserver = testScheduler.start { () -> Observable<Void> in
            return self.makeSut(
                didChangeAutoRotationModeEvents: didChangeAutoRotationModeEvents,
                didUpdateSpeedEvents: didUpdateSpeedEvents,
                onScheduler: self.testScheduler
            )
        }

        XCTAssert(hidesObserver.events.count == 1)
        XCTAssert(hidesObserver.events[0].time == 900)
    }

    func testWhenSubscribeOnBehaviorWhileSpeedIsMoreThanThresholdAndAutoRotationIsOnThenDrawerRemainsUntouched() {
        let didChangeAutoRotationModeEvents: [Recorded<Event<Bool>>] = [
            .next(300, false),
            .next(500, true)
        ]

        let didUpdateSpeedEvents: [Recorded<Event<Double>>] = [
            .next(400, 1.5),
            .next(600, 2.9)
        ]

        let hidesObserver = testScheduler.start(created: 100, subscribed: 700, disposed: 1000000) {
            return self.makeSut(
                didChangeAutoRotationModeEvents: didChangeAutoRotationModeEvents,
                didUpdateSpeedEvents: didUpdateSpeedEvents,
                onScheduler: self.testScheduler
            )
        }

        XCTAssert(hidesObserver.events.isEmpty)
    }
}
