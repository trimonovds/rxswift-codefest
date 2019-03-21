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

    typealias KudaGoEventCellConfigurator = CellConfigurator<KudaGoEventCell, KudaGoEvent>

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.dataSource = dataSource

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate(
            tableView.pinToParentSafe(withEdges: [.bottom, .left, .right]) +
            searchBar.pinToParentSafe(withEdges: [.top, .left, .right]) +
            [tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor)]
        )

        searchBar.rx.text.orEmpty
            .flatMapLatest { [weak self] searchText -> Observable<Result<[KudaGoEvent]>> in
                guard let slf = self else { return .empty() }
                return slf.googleSearchApi.searchEvents(with: searchText)
            }
            .observeOn(MainScheduler.instance)
            .bind(onNext: { [weak self] result in
                guard let slf = self else { return }
                switch result {
                case .success(let events):
                    slf.dataSource.sectionConfigurations = [
                        SectionConfigurator(cellConfigurators: events.map {
                            KudaGoEventCellConfigurator(model: $0)
                        })
                    ]
                    slf.tableView.reloadData()
                case .error(let error):
                    print(error)
                }
            })
            .disposed(by: bag)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }

    private let dataSource = TableViewDataSource()
    private let googleSearchApi = KudaGoSearchAPI(networkService: URLSession.shared)
    private let tableView: UITableView = UITableView()
    private let searchBar: UISearchBar = UISearchBar()
    private let bag = DisposeBag()
}

extension KudaGoSearchAPI {
    func searchEvents(with text: String) -> Observable<Result<[KudaGoEvent]>> {
        let asyncRequest = { (_ completion: @escaping (Result<[KudaGoEvent]>) -> Void) -> Task in
            return self.searchEvents(withText: text, completion: completion)
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
