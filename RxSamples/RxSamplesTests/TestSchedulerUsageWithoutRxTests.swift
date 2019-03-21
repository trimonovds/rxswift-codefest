//
//  TestSchedulerUsageWithoutRxTests.swift
//  RxSamplesTests
//
//  Created by Dmitry Trimonov on 21/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import Foundation
import XCTest
import RxTest
import RxSwift
import Utils
@testable import RxSamples

class TaskMock: Task {
    var onResume: (() -> Void)?
    var onCancel: (() -> Void)?

    init(onResume: (() -> Void)? = nil, onCancel: (() -> Void)? = nil) {
        self.onResume = onResume
        self.onCancel = onCancel
    }

    func resume() {
        onResume?()
    }
    func cancel() {
        onCancel?()
    }
}

class NetworkServiceMock: NetworkService {
    let requestImplementation: (URL, @escaping (Result<Data>) -> Void) -> Task

    init(requestImplementation: @escaping (URL, @escaping (Result<Data>) -> Void) -> Task) {
        self.requestImplementation = requestImplementation
    }

    func request(with url: URL, completion: @escaping (Result<Data>) -> Void) -> Task {
        return requestImplementation(url, completion)
    }
}

class GoogleSearchAPITests: XCTestCase {
    func testSearchWhenNetworkServiceRequestSucceedThenReturnsCorrectResutsInCompletion() {
        // Arrange
        let testScheduler = TestScheduler(initialClock: 0)
        let networkServiceMock = NetworkServiceMock { url, completion in
            var schedulingDisposable: Disposable?
            return TaskMock(onResume: {
                schedulingDisposable = testScheduler.scheduleRelativeVirtual((), dueTime: 500, action: { _ -> Disposable in
                    let data = "CodeFest is owesome conference!".data(using: .utf8)!
                    completion(.success(data))
                    return Disposables.create()
                })
            }, onCancel: {
                schedulingDisposable!.dispose()
            })
        }

        let sut = KudaGoSearchAPI(networkService: networkServiceMock)
        var actualResult: String?

        // Act
        testScheduler.scheduleAt(100) {
            let searchTask = sut.search(withText: "CodeFest") { (result) in
                actualResult = result.value
            }
            searchTask.resume()
        }

        // Assert
        testScheduler.advanceTo(599)
        XCTAssert(actualResult == nil)

        testScheduler.advanceTo(601)
        XCTAssert(actualResult == "CodeFest is owesome conference!")
    }

    func testSearchWhenNetworkServiceRequestCanceledSucceedThenReturnsCorrectResutsInCompletion() {
        // Arrange
        let testScheduler = TestScheduler(initialClock: 0)
        let networkServiceMock = NetworkServiceMock { url, completion in
            var schedulingDisposable: Disposable?
            return TaskMock(onResume: {
                schedulingDisposable = testScheduler.scheduleRelativeVirtual((), dueTime: 500, action: { _ -> Disposable in
                    let data = "CodeFest is owesome conference!".data(using: .utf8)!
                    completion(.success(data))
                    return Disposables.create()
                })
            }, onCancel: {
                schedulingDisposable!.dispose()
            })
        }

        let sut = KudaGoSearchAPI(networkService: networkServiceMock)
        var actualResult: String?

        // Act
        var searchTask: Task?
        testScheduler.scheduleAt(100) {
            searchTask = sut.search(withText: "CodeFest") { (result) in
                actualResult = result.value
            }
            searchTask!.resume()
        }

        testScheduler.scheduleAt(300) {
            searchTask!.cancel()
        }

        // Assert
        testScheduler.advanceTo(599)
        XCTAssert(actualResult == nil)

        testScheduler.advanceTo(601)
        XCTAssert(actualResult == nil)
    }
}

extension Result {
    var value: T? {
        switch self {
        case .success(let result):
            return result
        case .error(_):
            return nil
        }
    }
}
