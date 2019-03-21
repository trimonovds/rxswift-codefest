//
//  RxSamplesTests.swift
//  RxSamplesTests
//
//  Created by Dmitry Trimonov on 21/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import XCTest
import RxSwift
import RxTest
import RxCocoa
@testable import RxSamples

class CameraManagerOutputMock: CameraManagerOutput {
    let didChangeAutomaticRotationState: Observable<Bool>

    init(didChangeAutomaticRotationState: Observable<Bool>) {
        self.didChangeAutomaticRotationState = didChangeAutomaticRotationState
    }
}

class LocationManagerOutputMock: LocationManagerOutput {
    let didUpdateSpeed: Observable<Double>

    init(didUpdateSpeed: Observable<Double>) {
        self.didUpdateSpeed = didUpdateSpeed
    }
}

class DrawerInputMock: DrawerInput {

    var hides: Observable<Void> {
        return hideEventsPublisher.asObservable()
    }

    func hideIfPossible() {
        hideEventsPublisher.accept(())
    }

    private let hideEventsPublisher = PublishRelay<Void>()
}

class DrawerHidingBehaviorTests: XCTestCase {

    func testWhenSpeedExceedsLimitAndAutoRotationIsOnThenDrawerHides_UsingStartWithManualTimes() {
        let testScheduler = TestScheduler(initialClock: 0)
        let didChangeAutomaticRotationStateEvents: [Recorded<Event<Bool>>] = [
            .next(3, false),
            .next(6, true)
        ]
        let didChangeAutomaticRotationState = testScheduler.createHotObservable(didChangeAutomaticRotationStateEvents)
        let cameraManagerMock = CameraManagerOutputMock(
            didChangeAutomaticRotationState: didChangeAutomaticRotationState.asObservable()
        )

        let didUpdateSpeedEvents: [Recorded<Event<Double>>] = [
            .next(4, 1.5),
            .next(7, 2.0),
            .next(8, 2.51), // Exceeds
        ]
        let didUpdateSpeed = testScheduler.createHotObservable(didUpdateSpeedEvents)
        let locationManagerMock = LocationManagerOutputMock(didUpdateSpeed: didUpdateSpeed.asObservable())

        let drawerInputMock = DrawerInputMock()
        let sut = DrawerHidingBehavior(
            drawerInput: drawerInputMock,
            cameraManagerOutput: cameraManagerMock,
            locationManagerOutput: locationManagerMock
        )

        let hidesObserver = testScheduler.start(created: 0, subscribed: 1, disposed: 100000) { () -> Observable<Void> in
            return drawerInputMock.hides
        }

        XCTAssert(hidesObserver.events[0].time == 8)
    }

    // Observable sequence will be:
    // * created at virtual time `Defaults.created`           -> 100
    // * subscribed to at virtual time `Defaults.subscribed`  -> 200
    // * subscription will be disposed at `Defaults.disposed` -> 1000
    func testWhenSpeedExceedsLimitAndAutoRotationIsOnThenDrawerHides_UsingStartWithDefaults() {
        let testScheduler = TestScheduler(initialClock: 0)
        let didChangeAutomaticRotationStateEvents: [Recorded<Event<Bool>>] = [
            .next(300, false),
            .next(600, true)
        ]
        let didChangeAutomaticRotationState = testScheduler.createHotObservable(didChangeAutomaticRotationStateEvents)
        let cameraManagerMock = CameraManagerOutputMock(
            didChangeAutomaticRotationState: didChangeAutomaticRotationState.asObservable()
        )

        let didUpdateSpeedEvents: [Recorded<Event<Double>>] = [
            .next(400, 1.5),
            .next(700, 2.0),
            .next(800, 2.51), // Exceeds
        ]
        let didUpdateSpeed = testScheduler.createHotObservable(didUpdateSpeedEvents)
        let locationManagerMock = LocationManagerOutputMock(didUpdateSpeed: didUpdateSpeed.asObservable())

        let drawerInputMock = DrawerInputMock()
        let sut = DrawerHidingBehavior(
            drawerInput: drawerInputMock,
            cameraManagerOutput: cameraManagerMock,
            locationManagerOutput: locationManagerMock
        )

        let hidesObserver = testScheduler.start { () -> Observable<Void> in
            return drawerInputMock.hides
        }

        XCTAssert(hidesObserver.events.count == 1)
        XCTAssert(hidesObserver.events[0].time == 800)
    }
}
