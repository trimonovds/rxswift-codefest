//
//  ReuseCellSample.swift
//  RxPrimitivesLifecycle
//
//  Created by Dmitry Trimonov on 18/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Utils

public struct DefaultTableViewCellState {
    let text: String
    let detailText: String
}

extension Reactive where Base: UITableViewCell {

    /// Bindable sink for `state` property.
    public var state: Binder<DefaultTableViewCellState> {
        return Binder(self.base) { element, value in
            element.textLabel?.text = value.text
            element.detailTextLabel?.text = value.detailText
        }
    }
}

open class GenericBindableTableViewCell<ViewModelType: AnyObject>: BindableTableViewCell {
    public typealias Model = ViewModelType

    open func bind(to model: ViewModelType) {
        viewModel = model
    }

    private(set) var viewModel: ViewModelType? {
        didSet {
            binding = DisposeBag()
        }
    }

    private(set) var binding = DisposeBag()
}

class DefaultCellViewModel {
    let state = BehaviorRelay<DefaultTableViewCellState>(value: DefaultTableViewCellState(text: "", detailText: ""))
    let bag = DisposeBag()
}

class DefaultCell: GenericBindableTableViewCell<DefaultCellViewModel> {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func bind(to model: DefaultCellViewModel) {
        super.bind(to: model)
        model.state.bind(to: self.rx.state).disposed(by: binding)
    }
}

class CustomReactiveViewExtensionsViewController: UIViewController {

    typealias DefaultCellConfigurator = CellConfigurator<DefaultCell, DefaultCellViewModel>

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.dataSource = dataSource

        NSLayoutConstraint.activate(
            tableView.pinToParentSafe(withEdges: [.top, .bottom, .left, .right])
        )

        let moscowTimeCell = DefaultCellViewModel()
        Observable<Int>
            .interval(1.0, scheduler: MainScheduler.instance)
            .map { _ in () }
            .startWith(())
            .map { timeString -> DefaultTableViewCellState in
                let dateString = DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .none)
                let timeString = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
                return DefaultTableViewCellState(text: "Дата: \(dateString)", detailText: "Время: \(timeString)")
            }
            .bind(to: moscowTimeCell.state)
            .disposed(by: moscowTimeCell.bag)

        let currentDeviceOrientationCell = DefaultCellViewModel()
        UIApplication.shared.observableStatusBarOrientation
            .map { orientation -> DefaultTableViewCellState in
                let orientationString = orientation.isPortrait ? "Портрет" : "Лендскейп"
                return DefaultTableViewCellState(text: "Ориентация: \(orientationString)", detailText: "")
            }
            .bind(to: currentDeviceOrientationCell.state)
            .disposed(by: currentDeviceOrientationCell.bag)

        updateDataSource(with: [moscowTimeCell, currentDeviceOrientationCell])
    }

    func updateDataSource(with cellViewModels: [DefaultCellViewModel]) {
        dataSource.sectionConfigurations = [
            SectionConfigurator(cellConfigurators: cellViewModels.map { DefaultCellConfigurator(model: $0) })
        ]
    }

    private let dataSource = TableViewDataSource()
    private let tableView: UITableView = UITableView()
}

extension UIColor {
    static var random: UIColor {
        let r = CGFloat(Int.random(in: 0...255)) / 255
        let g = CGFloat(Int.random(in: 0...255)) / 255
        let b = CGFloat(Int.random(in: 0...255)) / 255
        return UIColor.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

extension UIApplication {

    public func statusBarOrientationChanges(withCurrent: Bool) -> Observable<UIInterfaceOrientation> {
        let orientationChanges = Observable<UIInterfaceOrientation>.create { subscriber in
            class BarOrientationObserver {
                let onOrientationChanged: (UIInterfaceOrientation) -> Void
                init(_ onOrientationChanged: @escaping (UIInterfaceOrientation) -> Void) {
                    self.onOrientationChanged = onOrientationChanged

                    NotificationCenter.default.addObserver(
                        self,
                        selector: #selector(handler),
                        name: UIApplication.didChangeStatusBarOrientationNotification,
                        object: nil
                    )
                }

                @objc func handler(notifitation: Notification) {
                    onOrientationChanged(UIApplication.shared.statusBarOrientation)
                }
            }

            let observer = BarOrientationObserver { subscriber.onNext($0) }
            return Disposables.create { NotificationCenter.default.removeObserver(observer) }
        }
        return withCurrent
            ? orientationChanges.startWith(UIApplication.shared.statusBarOrientation)
            : orientationChanges
    }

    public var observableStatusBarOrientation: Observable<UIInterfaceOrientation> {
        return statusBarOrientationChanges(withCurrent: true)
    }

}
