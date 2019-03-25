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

    enum ScreenState {
        case initial
        case searching
        case found([KudaGoEvent])
        case error
        case searchCanceled
    }

    var state: ScreenState = .initial {
        didSet {
            updateNetworkActivityIndicator(withIsLoading: state.isLoading)
            headerView.title = state.cardHeaderTitle
            if let events = state.events {
                updateTableView(with: events)
            }
        }
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
                slf.state = .searching
                let interruptions = slf.mapCamera
                    .filter { $0.state == .animating }
                    .do(onNext: { [weak slf] _ in
                        slf?.state = .searchCanceled
                    })
                let locationArgs = LocationArgs(coordinate: request.mapCamera.centerCoordinate, radius: slf.mapView.currentRadius())
                return slf.searchApi
                    .searchEvents(with: Constants.events, locationArgs: locationArgs)
                    .takeUntil(interruptions)
            }
            .observeOn(MainScheduler.instance)
            .bind(onNext: { [weak self] result in
                guard let slf = self else { return }
                switch result {
                case .success(let events):
                    slf.state = .found(events)
                case .error(_):
                    slf.state = .error
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

    private func updateNetworkActivityIndicator(withIsLoading isLoading: Bool) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = isLoading
    }
}

extension MKMapView {

    func topCenterCoordinate() -> CLLocationCoordinate2D {
        return self.convert(CGPoint(x: self.frame.size.width / 2.0, y: 0), toCoordinateFrom: self)
    }

    func currentRadius() -> Double {
        let centerLocation = CLLocation(latitude: self.centerCoordinate.latitude, longitude: self.centerCoordinate.longitude)
        let topCenterCoordinate = self.topCenterCoordinate()
        let topCenterLocation = CLLocation(latitude: topCenterCoordinate.latitude, longitude: topCenterCoordinate.longitude)
        return centerLocation.distance(from: topCenterLocation)
    }

}

extension MapKudaGoSearchViewController.ScreenState {
    var isLoading: Bool {
        switch self {
        case .searching:
            return true
        default:
            return false
        }
    }

    var events: [KudaGoEvent]? {
        switch self {
        case .found(let events):
            return events
        case .error:
            return []
        default:
            return nil
        }
    }

    var cardHeaderTitle: String {
        switch self {
        case .initial:
            return MapKudaGoSearchViewController.Constants.events
        case .error:
            return "Произошла ошибка"
        case .searching:
            return "Ищем \(MapKudaGoSearchViewController.Constants.events)..."
        case .found(let events):
            let count = events.count
            return count == 0 ? "Ничего не найдено" : "Найдено \(count) результатов"
        case .searchCanceled:
            return "Поиск отменен"
        }
    }
}
