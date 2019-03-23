import UIKit
import UltraDrawerView
import Utils
import MapKit

final class CardViewController: UIViewController {

    typealias ShapeCellConfigurator = CellConfigurator<ShapeCell, ShapeCellModel>

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(white: 0.9, alpha: 1.0)

        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(mapView.pinToParent())
        
        let headerView = CardHeaderView()
        headerView.title = "Shapes"
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.heightAnchor.constraint(equalToConstant: Constants.Header.headerHeight).isActive = true

        shapesDataSource.sectionConfigurations = [
            SectionConfigurator(cellConfigurators:
                ShapeCellModel.makeDefaults().map { ShapeCellConfigurator(model: $0) }
            )
        ]
        
        tableView.backgroundColor = .white
        tableView.dataSource = shapesDataSource
        tableView.contentInsetAdjustmentBehavior = .never
        
        drawerView = DrawerView(scrollView: tableView, delegate: self, headerView: headerView)
        drawerView.middlePosition = .fromBottom(Constants.Drawer.middleInsetFromBottom)
        drawerView.cornerRadius = Constants.Drawer.cornerRadius
        drawerView.containerView.backgroundColor = .white
        drawerView.layer.shadowRadius = Constants.Drawer.shadowRadius
        drawerView.layer.shadowOpacity = Constants.Drawer.shadowOpacity
        drawerView.layer.shadowOffset = Constants.Drawer.shadowOffset

        view.addSubview(drawerView)
        
        setupSettings()
        setupDrawerLayout()
        
        drawerView.setState(.middle, animated: false)

        setupBehaviors()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        let prevState = drawerView.state
        
        updateDrawerLayout(for: UIDevice.current.orientation)
        
        coordinator.animate(alongsideTransition: { [weak self] context in
            let newState: DrawerView.State = (prevState == .bottom) ? .bottom : .top
            self?.drawerView.setState(newState, animated: context.isAnimated)
        })
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        tableView.contentInset.bottom = view.safeAreaInsets.bottom
        tableView.scrollIndicatorInsets.bottom = view.safeAreaInsets.bottom
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let center = CLLocationCoordinate2D(latitude: 55.69454914, longitude: 37.60688340)
        let camera = MKMapCamera(lookingAtCenter: center, fromDistance: 67523, pitch: 0, heading: 0)
        mapView.setCamera(camera, animated: true)

        let orientation = UIDevice.current.orientation
        updateDrawerLayout(for: orientation)
        drawerView.setState(orientation.isLandscape ? .top : .middle, animated: false)
    }
    
    // MARK: - Private

    private let mapView = MKMapView()
    private let tableView = UITableView()
    private var drawerView: DrawerView!
    private let shapesDataSource = TableViewDataSource()
    private var isFirstLayout = true
    private var portraitConstraints: [NSLayoutConstraint] = []
    private var landscapeConstraints: [NSLayoutConstraint] = []

    private var drawerHidingBehavior: DrawerHidingBehavior?
    private let fakeLocationManager = FakeLocationManagerOutput()
    private let fakeCameraManager = FakeCameraManagerOutput()
}

fileprivate extension CardViewController {
    private enum Constants {
        enum Drawer {
            static let topInsetPortrait: CGFloat = 36
            static let topInsetLandscape: CGFloat = 20
            static let middleInsetFromBottom: CGFloat = 280
            static let cornerRadius: CGFloat = 16
            static let shadowRadius: CGFloat = 4
            static let shadowOpacity: Float = 0.2
            static let shadowOffset = CGSize.zero
        }
        enum Header {
            static let headerHeight: CGFloat = 64
        }
    }


    private func setupBehaviors() {
        drawerHidingBehavior = DrawerHidingBehavior(
            drawerInput: drawerView,
            cameraManagerOutput: fakeCameraManager,
            locationManagerOutput: fakeLocationManager
        )
    }

    private func setupDrawerLayout() {
        drawerView.translatesAutoresizingMaskIntoConstraints = false

        portraitConstraints = [
            drawerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            drawerView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            drawerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            drawerView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)
        ]

        landscapeConstraints = [
            drawerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            drawerView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16),
            drawerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            drawerView.widthAnchor.constraint(equalToConstant: 320)
        ]
    }

    private func updateDrawerLayout(for orientation: UIDeviceOrientation) {
        if orientation.isLandscape {
            portraitConstraints.forEach { $0.isActive = false }
            landscapeConstraints.forEach { $0.isActive = true }
            drawerView.topPosition = .fromTop(Constants.Drawer.topInsetLandscape)
            drawerView.availableStates = [.top, .bottom]
        } else {
            landscapeConstraints.forEach { $0.isActive = false }
            portraitConstraints.forEach { $0.isActive = true }
            drawerView.topPosition = .fromTop(Constants.Drawer.topInsetPortrait)
            drawerView.availableStates = [.top, .middle, .bottom]
        }
    }
}

extension CardViewController: UIScrollViewDelegate { }

extension CardViewController {

    // MARK: - Buttons
    
    private func setupSettings() {
        let settingsViews = [
            makeButton(withTitle: "Reset", action: #selector(handleResetButton)),
            makeButton(withTitle: "Speed +", action: #selector(handleSpeedUpButton)),
            makeButton(withTitle: "Speed -", action: #selector(handleSlowDownButton)),
            makeSwitch(initialValue: fakeCameraManager.isOn.value, name: "AutoRotation", action: #selector(handleAutorotationSwitch))
        ]

        let settingsView = UIStackView(arrangedSubviews: settingsViews)
        view.addSubview(settingsView)
        settingsView.spacing = 8.0
        settingsView.translatesAutoresizingMaskIntoConstraints = false
        settingsView.axis = .vertical
        settingsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8.0).isActive = true
        settingsView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -8.0).isActive = true
    }

    func makeButton(withTitle title: String, action: Selector) -> UIView {
        let button = UIButton(type: .system)
        button.backgroundColor = .darkGray
        button.titleLabel?.font = .boldSystemFont(ofSize: UIFont.buttonFontSize)
        button.tintColor = .white
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    func makeSwitch(initialValue: Bool, name: String, action: Selector) -> UIView {
        let uiSwitch = UISwitch()
        uiSwitch.translatesAutoresizingMaskIntoConstraints = false
        uiSwitch.isOn = initialValue
        uiSwitch.addTarget(self, action: action, for: .valueChanged)
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = name
        title.textColor = .white
        let stackView = UIStackView(arrangedSubviews: [title, uiSwitch])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.spacing = 8.0

        let stackViewContainer = UIView()
        stackViewContainer.layer.cornerRadius = 8.0
        stackViewContainer.layer.masksToBounds = true
        stackViewContainer.backgroundColor = .darkGray
        stackViewContainer.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(stackView.pinToParent(withInsets: .all(8.0)))
        return stackViewContainer
    }

    @objc private func handleResetButton() {
        drawerView.setState(.top, animated: true)
    }

    @objc private func handleSpeedUpButton() {
        fakeLocationManager.speed.accept(fakeLocationManager.speed.value + 1)
    }
    
    @objc private func handleSlowDownButton() {
        fakeLocationManager.speed.accept(fakeLocationManager.speed.value - 1)
    }

    @objc private func handleAutorotationSwitch(_ sender: UISwitch) {
        fakeCameraManager.isOn.accept(sender.isOn)
    }
}
