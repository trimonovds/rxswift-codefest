//
//  GoogleSearchViewController.swift
//  RxSamples
//
//  Created by Dmitry Trimonov on 21/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import UIKit
import Utils
import RxSwift
import RxCocoa

class KudaGoSearchViewController: UIViewController, UITableViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(pageContentView)
        pageContentView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate(
            pageContentView.pinToParentSafe(withEdges: [.bottom, .left, .right]) +
            searchBar.pinToParentSafe(withEdges: [.top, .left, .right]) +
            [pageContentView.topAnchor.constraint(equalTo: searchBar.bottomAnchor)]
        )

        searchBar.rx.text.orEmpty
            .flatMapLatest { [weak self] searchText -> Observable<Result<String>> in
                guard let slf = self else { return .empty() }
                return slf.googleSearchApi.search(with: searchText)
            }
            .observeOn(MainScheduler.instance)
            .bind(onNext: { [weak self] result in
                guard let slf = self else { return }
                switch result {
                case .success(let pageContent):
                    slf.pageContentView.text = pageContent
                case .error(let error):
                    print(error)
                    slf.pageContentView.text = String(describing: error)
                }
            })
            .disposed(by: bag)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }

    private var currentSearchTask: Task?
    private let googleSearchApi = KudaGoSearchAPI(networkService: URLSession.shared)
    private let pageContentView: UITextView = UITextView()
    private let searchBar: UISearchBar = UISearchBar()
    private let bag = DisposeBag()
}

extension KudaGoSearchAPI {
    func search(with text: String) -> Observable<Result<String>> {
        let asyncRequest = { (_ completion: @escaping (Result<String>) -> Void) -> Task in
            return self.search(withText: text, completion: completion)
        }
        return Observable.fromAsync(asyncRequest)
    }
}

extension Observable {
    static func fromAsync(_ asyncRequest: @escaping (@escaping (Element) -> Void) -> Task) -> Observable<Element> {
        return Observable.create({ (o) -> Disposable in
            let task = asyncRequest({ (result) in
                o.onNext(result)
                o.onCompleted()
            })
            task.resume()
            return Disposables.create {
                task.cancel()
            }
        })
    }
}
