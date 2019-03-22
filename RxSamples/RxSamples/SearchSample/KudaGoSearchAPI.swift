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

public enum NetworkError: Swift.Error {
    /// Unknown error occurred.
    case unknown
    /// Response is not NSHTTPURLResponse
    case nonHTTPResponse(response: URLResponse)
    /// Response is not successful. (not in `200 ..< 300` range)
    case httpRequestFailed(response: HTTPURLResponse, data: Data?)
    /// Deserialization error.
    case deserializationError(error: Swift.Error)

    var description: String {
        switch self {
        case .unknown:
            return "Неизвестная ошибка"
        case .nonHTTPResponse(_):
            return "Ошибка сервера"
        case .httpRequestFailed(_):
            return "Не удалось получить данные"
        case .deserializationError(_):
            return "Ошибка сериализации"
        }
    }
}

class KudaGoSearchAPI {

    typealias Response = KudaGoEventsPageResponse

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func searchEvents(withText searchText: String, completion: @escaping (Result<[KudaGoEvent]>) -> Void) -> Task {
        let url = KudaGoSearchAPI.makeURL(for: searchText)
        let task = networkService.request(with: url) { (result) in
            switch result {
            case .success(let data):
                do {
                    let response: Response = try JSONDecoder().decode(Response.self, from: data)
                    completion(.success(response.results))
                } catch {
                    completion(.error(NetworkError.deserializationError(error: error)))
                }
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
            guard let response = response, let data = data else {
                completion(.error(error ?? NetworkError.unknown))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.error(NetworkError.nonHTTPResponse(response: response)))
                return
            }

            if 200 ..< 300 ~= httpResponse.statusCode {
                completion(.success(data))
            }
            else {
                completion(.error(NetworkError.httpRequestFailed(response: httpResponse, data: data)))
            }
        }
        return urlSessionTask
    }
}
