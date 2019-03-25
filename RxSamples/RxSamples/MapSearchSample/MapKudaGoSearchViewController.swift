//
//  MapViewController.swift
//  RxSamples
//
//  Created by Dmitry Trimonov on 25/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import UIKit
import MapKit
import RxSwift
import RxCocoa
import Utils
import UltraDrawerView

class MapKudaGoSearchViewController: MapDrawerViewController {

    enum MapCameraState {
        case idle
        case animating
    }

    struct MapCameraEventArgs {
        let mapCamera: MKMapCamera
        let state: MapCameraState
    }

    var mapCamera: BehaviorRelay<MapCameraEventArgs>!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundColor = .white
        tableView.dataSource = dataSource

        mapCamera = BehaviorRelay<MapCameraEventArgs>(value: MapCameraEventArgs(mapCamera: mapView.camera, state: .idle))
        let finishedCameraMoves = mapCamera.filter { $0.state == .idle }
        finishedCameraMoves
            .debounce(0.25, scheduler: MainScheduler.instance)
            .flatMapLatest { [weak self] args -> Observable<Result<[KudaGoEvent], SearchScreenError>> in
                guard let slf = self else { return .empty() }
                slf.update(withIsLoading: true)
                return slf.searchApi.searchEvents(with: Constants.events, coordinate: args.mapCamera.centerCoordinate)
                    .map {
                        switch $0 {
                        case .success(let events): return .success(events)
                        case .error(let apiError): return .error(.api(apiError))
                        }
                    }
                    .timeout(5.0, scheduler: MainScheduler.instance)
                    .catchError({ (err) -> Observable<Result<[KudaGoEvent], SearchScreenError>> in
                        guard case RxError.timeout = err else {
                            assert(false)
                            return .just(.error(.api(.unknown)))
                        }
                        return .just(.error(.timeout))
                    })
            }
            .observeOn(MainScheduler.instance)
            .bind(onNext: { [weak self] result in
                guard let slf = self else { return }
                slf.update(withIsLoading: false)
                switch result {
                case .success(let events):
                    slf.updateTableView(with: events)
                case .error(_):
                    slf.updateTableView(with: [])
                }
            })
            .disposed(by: bag)
    }

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        self.mapCamera.accept(.init(mapCamera: mapView.camera, state: .animating))
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        self.mapCamera.accept(.init(mapCamera: mapView.camera, state: .idle))
    }

    private let dataSource = TableViewDataSource()
    private let searchApi = KudaGoSearchAPI(session: URLSession.shared)
    private let bag = DisposeBag()
}

fileprivate extension MapKudaGoSearchViewController {

    enum Constants {
        static let events: String = "Спектакли"
    }

    private func updateTableView(with events: [KudaGoEvent]) {
        dataSource.sectionConfigurations = [
            SectionConfigurator(cellConfigurators: events.map {
                KudaGoEventCellConfigurator(model: $0)
            })
        ]
        tableView.reloadData()
    }

    private func update(withIsLoading isLoading: Bool) {
        self.headerView.title = isLoading ? "Ищем \(Constants.events) по близости..." : Constants.events
        UIApplication.shared.isNetworkActivityIndicatorVisible = isLoading
    }
}
