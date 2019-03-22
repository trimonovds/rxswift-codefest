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

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.dataSource = dataSource

        view.addSubview(errorBar)
        errorBar.translatesAutoresizingMaskIntoConstraints = false
        errorBar.numberOfLines = 2
        errorBar.font = UIFont.systemFont(ofSize: 14.0)
        errorBar.backgroundColor = UIColor.red.withAlphaComponent(0.8)
        errorBar.textColor = UIColor.white

        view.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        errorBarTopConstraint = errorBar.topAnchor.constraint(equalTo: searchBar.bottomAnchor)
        updateErrorBarTopConstraint(forIsError: false)

        NSLayoutConstraint.activate(
            searchBar.pinToParentSafe(withEdges: [.top, .left, .right]) +
            tableView.pinToParentSafe(withEdges: [.bottom, .left, .right]) +
            errorBar.pinToParentSafe(withEdges: [.left, .right]) +
            [
                errorBarTopConstraint,
                tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
                errorBar.heightAnchor.constraint(equalToConstant: L.errorBarHeight)
            ]
        )

        searchBar.rx.text.orEmpty
            .debounce(0.25, scheduler: MainScheduler.instance)
            .flatMapLatest { [weak self] searchText -> Observable<Result<[KudaGoEvent]>> in
                guard let slf = self else { return .empty() }
                return slf.searchApi.searchEvents(with: searchText)
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
                    slf.dataSource.sectionConfigurations = []
                    slf.tableView.reloadData()
                    slf.errorBar.text = (error as? NetworkError)?.description ?? error.localizedDescription
                }

                slf.view.layoutIfNeeded()
                UIView.animate(
                    withDuration: 0.25,
                    delay: 0.0,
                    options: UIView.AnimationOptions.beginFromCurrentState,
                    animations: {
                        slf.updateErrorBarTopConstraint(forIsError: result.isError)
                        slf.view.layoutIfNeeded()
                    },
                    completion: nil
                )
            })
            .disposed(by: bag)
    }

    private let dataSource = TableViewDataSource()
    private let searchApi = KudaGoSearchAPI(networkService: URLSession.shared)
    private let tableView: UITableView = UITableView()
    private let searchBar: UISearchBar = UISearchBar()
    private let errorBar: UILabel = UILabel()
    private var errorBarTopConstraint: NSLayoutConstraint!
    private let bag = DisposeBag()
}

fileprivate extension KudaGoSearchViewController {
    enum L {
        static let errorBarHeight: CGFloat = 20.0
    }

    private func updateErrorBarTopConstraint(forIsError isError: Bool) {
        errorBarTopConstraint.constant = isError ? 0.0 : -L.errorBarHeight
    }
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
