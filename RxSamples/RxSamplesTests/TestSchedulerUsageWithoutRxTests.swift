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
    let taskIdentifier: Int
    var onResume: (() -> Void)?
    var onCancel: (() -> Void)?

    init(taskIdentifier: Int, onResume: (() -> Void)? = nil, onCancel: (() -> Void)? = nil) {
        self.taskIdentifier = taskIdentifier
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

extension TaskMock {
    static let NopTask: Task = TaskMock(taskIdentifier: Int.max, onResume: nil, onCancel: nil)
}

class SearchManagerTests: XCTestCase {
    func testSearchWhenNetworkServiceRequestSucceedThenReturnsCorrectResutsInCompletion() {
        // Arrange
        let testScheduler = TestScheduler(initialClock: 0)
        let networkServiceMock = NetworkServiceMock { url, completion in
            guard url.absoluteString.contains("CodeFest") else {
                return TaskMock.NopTask
            }

            let response = "CodeFest is owesome conference!"
            let data = response.data(using: .utf8)!

            let cancellation = testScheduler.scheduleRelativeVirtual((), dueTime: 500, action: { _ -> Disposable in
                completion(.success(data))
                return Disposables.create()
            })

            return TaskMock(taskIdentifier: 1, onResume: nil, onCancel: {
                cancellation.dispose()
            })
        }

        let sut = SearchManager(networkService: networkServiceMock)
        var actualResult: String?
        let expectedResult = "CodeFest is owesome conference!"

        // Act
        var searchTask: Task?

        testScheduler.scheduleAt(100) {
            searchTask = sut.search(withText: "CodeFest") { (result) in
                actualResult = result.value
            }
        }

        // Assert
        testScheduler.advanceTo(599)
        XCTAssert(actualResult == nil)

        testScheduler.advanceTo(601)
        XCTAssert(actualResult == expectedResult)
    }

    func testSearchWhenNetworkServiceRequestCanceledSucceedThenReturnsCorrectResutsInCompletion() {
        // Arrange
        let testScheduler = TestScheduler(initialClock: 0)
        let networkServiceMock = NetworkServiceMock { url, completion in
            guard url.absoluteString.contains("CodeFest") else {
                return TaskMock.NopTask
            }

            let response = "CodeFest is owesome conference!"
            let data = response.data(using: .utf8)!

            let cancellation = testScheduler.scheduleRelativeVirtual((), dueTime: 500, action: { _ -> Disposable in
                completion(.success(data))
                return Disposables.create()
            })

            return TaskMock(taskIdentifier: 1, onResume: nil, onCancel: {
                cancellation.dispose()
            })
        }

        let sut = SearchManager(networkService: networkServiceMock)
        var actualResult: String?
        let expectedResult = "CodeFest is owesome conference!"

        // Act
        var searchTask: Task?

        testScheduler.scheduleAt(100) {
            searchTask = sut.search(withText: "CodeFest") { (result) in
                actualResult = result.value
            }
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
