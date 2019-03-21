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
    func resume()
    func cancel()
}

protocol NetworkService {
    func request(with url: URL, completion: @escaping (Result<Data>) -> Void) -> Task
}

struct KudaGoEventsPageResponse: Codable {
    var count: Int
    var next: String?
    var previos: String?
    var results: [KudaGoEvent]
}

class KudaGoSearchAPI {

    typealias Response = KudaGoEventsPageResponse

    struct SerializationError: Error { }

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func searchEvents(withText searchText: String, completion: @escaping (Result<[KudaGoEvent]>) -> Void) -> Task {
        let url = KudaGoSearchAPI.makeURL(for: searchText)
        let task = networkService.request(with: url) { (result) in
            switch result {
            case .success(let data):
                guard let response: Response = try? JSONDecoder().decode(Response.self, from: data) else {
                    completion(.error(SerializationError()))
                    return
                }
                completion(.success(response.results))
            case .error(let err):
                completion(.error(err))
            }
        }
        return task
    }

    private let networkService: NetworkService
}

fileprivate extension KudaGoSearchAPI {
    static func makeURL(for searchText: String) -> URL {
        let urlString = { (s: String) -> String in
            return "https://kudago.com/public-api/v1.4/search/?q=\(s)&location=msk&ctype=event"
        }
        let url: URL
        if let query = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let textURL = URL(string: urlString(query)) {
            url = textURL
        } else {
            url = URL(string: urlString(""))!
        }
        return url
    }
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
