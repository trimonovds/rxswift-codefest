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
    func request(with url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> Task
}

struct KudaGoEventsPageResponse: Codable {
    var count: Int
    var next: String?
    var previos: String?
    var results: [KudaGoEvent]
}

enum APIError: Swift.Error {
    /// When response, data, error are all nil
    case unknown
    /// Raw URLSession.dataTask error
    case URLSessionError(error: Swift.Error)
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
        case .URLSessionError(let error):
            return error.localizedDescription
        case .deserializationError(let error):
            return error.localizedDescription
        case .nonHTTPResponse(_):
            return "Неизвестная ошибка сервера"
        case .httpRequestFailed(_,_):
            return "Не удалось получить данные"
        }
    }
}

class KudaGoSearchAPI {

    typealias Response = KudaGoEventsPageResponse

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func searchEvents(withText searchText: String, completion: @escaping (Result<[KudaGoEvent], APIError>) -> Void) -> Task {
        let url = KudaGoSearchAPI.makeURL(for: searchText)
        let task = networkService.request(with: url) { (data, response, error) in
            guard let response = response, let data = data else {
                completion(.error(error.flatMap { APIError.URLSessionError(error: $0) } ?? APIError.unknown))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.error(APIError.nonHTTPResponse(response: response)))
                return
            }

            if 200 ..< 300 ~= httpResponse.statusCode {
                do {
                    let response: Response = try JSONDecoder().decode(Response.self, from: data)
                    completion(.success(response.results))
                } catch {
                    completion(.error(APIError.deserializationError(error: error)))
                }
            }
            else {
                completion(.error(APIError.httpRequestFailed(response: httpResponse, data: data)))
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
    func request(with url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> Task {
        let urlSessionTask = self.dataTask(with: url) { (data, response, error) in
            completion(data, response, error)
        }
        return urlSessionTask
    }
}
