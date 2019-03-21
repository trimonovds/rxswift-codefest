//
//  SearchManager.swift
//  RxSamples
//
//  Created by Dmitry Trimonov on 21/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import Foundation
import Utils

protocol Task: AnyObject {
    var taskIdentifier: Int { get }
    func resume()
    func cancel()
}

protocol NetworkService {
    func request(with url: URL, completion: @escaping (Result<Data>) -> Void) -> Task
}

class SearchManager {

    struct UnknownResponseError: Error { }

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func search(withText text: String, completion: @escaping (Result<String>) -> Void) -> Task {
        let query = text.split(separator: " ").joined(separator: "+")
        let url = URL(string: "http://www.google.com/search?q=\(query)")!
        let task = networkService.request(with: url) { (result) in
            switch result {
            case .success(let data):
                if let parsedResult = String(data: data, encoding: .utf8) {
                    completion(.success(parsedResult))
                } else {
                    completion(.error(UnknownResponseError()))
                }
            case .error(let err):
                completion(.error(err))
            }
        }
        return task
    }

    private let networkService: NetworkService
}

extension URLSessionTask: Task { }
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
