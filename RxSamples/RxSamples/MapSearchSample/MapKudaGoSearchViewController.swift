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

    let mapCamera = PublishRelay<MapCameraEventArgs>()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundColor = .white
        tableView.dataSource = dataSource

        let finishedCameraMoves = mapCamera.filter { $0.state == .idle }
        let searchRequests = finishedCameraMoves
            .debounce(0.5, scheduler: MainScheduler.instance)
            .withLatestFrom(mapCamera)
            .filter { $0.state != .animating }

        searchRequests
            .flatMapLatest { [weak self] request -> Observable<Result<[KudaGoEvent], APIError>> in
                guard let slf = self else { return .empty() }
                slf.update(withIsLoading: true)
                let interruptions = slf.mapCamera
                    .filter { $0.state == .animating }
                    .do(onNext: { [weak slf] _ in
                        slf?.headerView.title = "Поиск отменен"
                    })
                return slf.searchApi
                    .searchEvents(with: Constants.events, coordinate: request.mapCamera.centerCoordinate)
                    .takeUntil(interruptions)
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let center = CLLocationCoordinate2D(latitude: 55.69454914, longitude: 37.60688340)
        let camera = MKMapCamera(lookingAtCenter: center, fromDistance: 67523, pitch: 0, heading: 0)
        mapView.setCamera(camera, animated: true)
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
        self.headerView.title = isLoading ? "Ищем \(Constants.events)..." : Constants.events
        UIApplication.shared.isNetworkActivityIndicatorVisible = isLoading
    }
}

extension Swift.Error {
    var isRxTimeout: Bool {
        guard let rxError = self as? RxError else { return false }
        if case .timeout = rxError {
            return true
        } else {
            return false
        }
    }
}
