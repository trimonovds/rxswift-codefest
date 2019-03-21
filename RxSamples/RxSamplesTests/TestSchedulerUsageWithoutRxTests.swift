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

protocol Task {
    var taskIdentifier: Int { get }
    func resume()
    func cancel()
}

enum Result<T> {
    case success(T)
    case error(Error)
}

protocol NetworkService {
    func request(with url: URL, completion: @escaping (Result<Data>) -> Void) -> Task
}

protocol Logger {
    func logMessage(_ message: String)
}

extension Logger {
    func log<T>(_ subject: T) {
        let message = String(describing: subject)
        logMessage(message)
    }
}

extension URLSession: NetworkService {
    func request(with url: URL, completion: @escaping (Result<Data>) -> Void) -> Task {
        let urlSessionTask = self.dataTask(with: url) { (data, response, error) in
            if let err = error {
                completion(.error(err))
            } else {
                completion(.success(data!))
            }
        }
        return urlSessionTask
    }
}

struct SearchResult: Equatable {
    let name: String
}
extension URLSessionTask: Task { }

class SearchManager {
    init(networkService: NetworkService, logger: Logger) {
        self.networkService = networkService
        self.logger = logger
    }

    func search(withText text: String, completion: @escaping (Result<[SearchResult]>) -> Void) -> Task {
        let query = text.split(separator: " ").joined(separator: "+")
        let url = URL(string: "http://www.google.com/search?q=\(query)")!
        logger.log(url)
        let task = networkService.request(with: url) { [weak self] (result) in
            switch result {
            case .success(let data):
                let parsedResults = SearchManager.parse(from: data)
                self?.logger.log("Results count: \(parsedResults.count)")
                completion(.success(parsedResults))
            case .error(let err):
                self?.logger.log(err)
                completion(.error(err))
            }
        }
        return task
    }

    static func parse(from data: Data) -> [SearchResult] {
        return String(data: data, encoding: .utf8)?.split(separator: ",").map { SearchResult(name: String($0)) } ?? []
    }

    private let networkService: NetworkService
    private let logger: Logger
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

class LoggerMock: Logger {
    var messages: [String] = []

    func logMessage(_ message: String) {
        messages.append(message)
    }
}

struct TaskMock: Task {
    let taskIdentifier: Int
    var onResume: (() -> Void)?
    var onCancel: (() -> Void)?

    func resume() {
        onResume?()
    }
    func cancel() {
        onCancel?()
    }
}

class SearchManagerTests: XCTestCase {
    func testSearchWhenNetworkServiceRequestSucceedThenLogResultsCountAndCorrectResutsInCompletion() {
        let testScheduler = TestScheduler(initialClock: 0)
        let networkServiceMock = NetworkServiceMock { url, completion in
            let searchResultNames = "ABBA,Queen"
            let data = searchResultNames.data(using: .utf8)!

            let cancellation = testScheduler.scheduleAbsoluteVirtual((), time: 500, action: { _ -> Disposable in
                completion(.success(data))
                return Disposables.create()
            })

            return TaskMock(taskIdentifier: 1, onResume: nil, onCancel: {
                cancellation.dispose()
            })
        }
        let loggerMock = LoggerMock()
        let sut = SearchManager(networkService: networkServiceMock, logger: loggerMock)

        let task = sut.search(withText: "Most famous groups") { (result) in
            XCTAssert(result.value == [SearchResult(name: "ABBA"), SearchResult(name: "Queen")])
        }
        testScheduler.advanceTo(499)

        let resultsCountsMessageExpectedMessage = "Results count: 2"
        XCTAssert(!loggerMock.messages.contains(resultsCountsMessageExpectedMessage))

        testScheduler.advanceTo(501)
        XCTAssert(loggerMock.messages.contains(resultsCountsMessageExpectedMessage))
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
