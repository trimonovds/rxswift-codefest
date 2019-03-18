//
//  WayPointsSample.swift
//  RxPrimitivesLifecycle
//
//  Created by Dmitry Trimonov on 18/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import Foundation
import Utils
import RxSwift
import RxCocoa
import CoreLocation

class WayPointsViewController: UIViewController, UITableViewDelegate {

    typealias WayPointCellConfigurator = CellConfigurator<WayPointCell, WayPointViewModel>

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.dataSource = dataSource
        tableView.delegate = self

        NSLayoutConstraint.activate(
            tableView.pinToParentSafe(withEdges: [.top, .bottom, .left, .right])
        )

        let cellViewModels: [WayPointViewModel] = (0...100).map { i -> WayPointViewModel in
            let state: WayPointState = Int.random(in: (0...1)) == 1
                ? .empty
                : .filled(WayPoint.init(name: "Точка \(i)", point: CLLocationCoordinate2DMake(1, 2)))
            let cellVm = WayPointViewModel()
            cellVm.taps.bind {
                cellVm.state.accept(.empty)
            }.disposed(by: cellVm.bag)
            cellVm.state.accept(state)
            return cellVm
        }
        updateDataSource(with: cellViewModels)
    }

    func updateDataSource(with cellViewModels: [WayPointViewModel]) {
        dataSource.sectionConfigurations = [
            SectionConfigurator(cellConfigurators: cellViewModels.map { WayPointCellConfigurator(model: $0) })
        ]
    }

    private let dataSource = TableViewDataSource()
    private let tableView: UITableView = UITableView()
}

enum WayPointState {
    case empty
    case filled(WayPoint)
}

struct WayPoint {
    let name: String
    let point: CLLocationCoordinate2D
}

class WayPointViewModel {
    var boundTimes: Int = 0
    var state = BehaviorRelay<WayPointState>(value: .empty)
    var taps = PublishSubject<Void>()
    var bag = DisposeBag()
}

class BindableView<ViewModelType: AnyObject>: View {
    typealias Model = ViewModelType

    func bind(to model: ViewModelType) {
        viewModel = model
    }

    private var viewModel: ViewModelType? {
        didSet {
            binding = DisposeBag()
        }
    }

    private(set) var binding = DisposeBag()
}

class WayPointCellView: BindableView<WayPointViewModel> {
    override init(frame: CGRect) {
        super.init(frame: frame)

        makeEmptyButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(makeEmptyButton)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)

        boundTimesLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(boundTimesLabel)

        makeEmptyButton.setTitle("x", for: .normal)
        makeEmptyButton.setTitleColor(.black, for: .normal)

        nameLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        boundTimesLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)

        nameLabel.textColor = .black
        boundTimesLabel.textColor = .gray

        NSLayoutConstraint.activate(
            nameLabel.pinToParent(withEdges: [.left, .top]) +
                boundTimesLabel.pinToParent(withEdges: [.left, .bottom]) +
                [
                    boundTimesLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8.0),
                    makeEmptyButton.heightAnchor.constraint(equalToConstant: 20),
                    makeEmptyButton.widthAnchor.constraint(equalToConstant: 20)
                ] +
                makeEmptyButton.pinToParent(withEdges: [.right]) +
                makeEmptyButton.centerInParent(.vertically)
        )

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func bind(to viewModel: WayPointViewModel) {
        super.bind(to: viewModel)
        viewModel.boundTimes += 1

        self.boundTimesLabel.text = "Bound \(viewModel.boundTimes) times"

        viewModel.state.bind(onNext: { [weak self] state in
            guard let slf = self else { return }

            switch state {
            case .empty:
                slf.nameLabel.text = "Неизвестно"
                slf.makeEmptyButton.alpha = 0.0
            case .filled(let wp):
                slf.nameLabel.text = wp.name
                slf.makeEmptyButton.alpha = 1.0
            }
        }).disposed(by: binding)

        makeEmptyButton.rx.tap.bind(to: viewModel.taps).disposed(by: binding)

    }

    private let nameLabel = UILabel()
    private let boundTimesLabel = UILabel()
    private let makeEmptyButton = UIButton(type: .system)
}

class WayPointCell: TableViewCell {
    typealias Model = WayPointViewModel

    func bind(to viewModel: WayPointViewModel) {
        let newView = WayPointCellView(frame: .zero)
        newView.bind(to: viewModel)
        view = newView
    }

    var view: WayPointCellView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let v = view {
                v.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview(v)
                NSLayoutConstraint.activate(
                    v.pinToParent(withInsets: UIEdgeInsets.init(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0))
                )
            }
        }
    }
}
