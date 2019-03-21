import UIKit
import UltraDrawerView
import Utils
import MapKit

final class CardViewController: UIViewController {

    typealias ShapeCellConfigurator = CellConfigurator<ShapeCell, ShapeCellModel>

    private struct Layout {
        static let topInsetPortrait: CGFloat = 36
        static let topInsetLandscape: CGFloat = 20
        static let middleInsetFromBottom: CGFloat = 280
        static let headerHeight: CGFloat = 64
        static let cornerRadius: CGFloat = 16
        static let shadowRadius: CGFloat = 4
        static let shadowOpacity: Float = 0.2
        static let shadowOffset = CGSize.zero
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(white: 0.9, alpha: 1.0)

        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(mapView.pinToParent())
        
        let headerView = CardHeaderView()
        headerView.title = "Shapes"
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.heightAnchor.constraint(equalToConstant: Layout.headerHeight).isActive = true

        shapesDataSource.sectionConfigurations = [
            SectionConfigurator(cellConfigurators:
                ShapeCellModel.makeDefaults().map { ShapeCellConfigurator(model: $0) }
            )
        ]
        
        tableView.backgroundColor = .white
        tableView.dataSource = shapesDataSource
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        
        drawerView = DrawerView(scrollView: tableView, delegate: self, headerView: headerView)
        drawerView.middlePosition = .fromBottom(Layout.middleInsetFromBottom)
        drawerView.cornerRadius = Layout.cornerRadius
        drawerView.containerView.backgroundColor = .white
        drawerView.layer.shadowRadius = Layout.shadowRadius
        drawerView.layer.shadowOpacity = Layout.shadowOpacity
        drawerView.layer.shadowOffset = Layout.shadowOffset

        view.addSubview(drawerView)
        
        setupSettings()
        setupLayout()
        
        drawerView.setState(.middle, animated: false)

        setupBehaviors()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if isFirstLayout {
            isFirstLayout = false
            updateLayoutWithCurrentOrientation()
            drawerView.setState(UIDevice.current.orientation.isLandscape ? .top : .middle, animated: false)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        let prevState = drawerView.state
        
        updateLayoutWithCurrentOrientation()
        
        coordinator.animate(alongsideTransition: { [weak self] context in
            let newState: DrawerView.State = (prevState == .bottom) ? .bottom : .top
            self?.drawerView.setState(newState, animated: context.isAnimated)
        })
    }
    
    @available(iOS 11.0, *)
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

    private func setupBehaviors() {
        drawerHidingBehavior = DrawerHidingBehavior(
            drawerInput: drawerView,
            cameraManagerOutput: fakeCameraManager,
            locationManagerOutput: fakeLocationManager
        )
    }
    
    private func setupLayout() {
        drawerView.translatesAutoresizingMaskIntoConstraints = false
    
        portraitConstraints = [
            drawerView.topAnchor.constraint(equalTo: view.topAnchor),
            drawerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            drawerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            drawerView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ]
        
        let landscapeLeftAnchor: NSLayoutXAxisAnchor
        if #available(iOS 11.0, *) {
            landscapeLeftAnchor = view.safeAreaLayoutGuide.leftAnchor
        } else {
            landscapeLeftAnchor = view.leftAnchor
        }
        
        landscapeConstraints = [
            drawerView.topAnchor.constraint(equalTo: view.topAnchor),
            drawerView.leftAnchor.constraint(equalTo: landscapeLeftAnchor, constant: 16),
            drawerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            drawerView.widthAnchor.constraint(equalToConstant: 320)
        ]
    }
    
    private func updateLayoutWithCurrentOrientation() {
        let orientation = UIDevice.current.orientation
        
        if orientation.isLandscape {
            portraitConstraints.forEach { $0.isActive = false }
            landscapeConstraints.forEach { $0.isActive = true }
            drawerView.topPosition = .fromTop(Layout.topInsetLandscape)
            drawerView.availableStates = [.top, .bottom]
        } else if orientation.isPortrait {
            landscapeConstraints.forEach { $0.isActive = false }
            portraitConstraints.forEach { $0.isActive = true }
            drawerView.topPosition = .fromTop(Layout.topInsetPortrait)
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
        settingsView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8.0).isActive = true
        settingsView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8.0).isActive = true
    }

    func makeButton(withTitle title: String, action: Selector) -> UIView {
        let button = UIButton(type: .system)
        button.backgroundColor = .darkGray
        button.titleLabel?.font = .boldSystemFont(ofSize: UIFont.systemFontSize)
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
        title.backgroundColor = .white
        title.text = name
        title.textColor = .black
        let uiSwitchContainer = UIStackView(arrangedSubviews: [title, uiSwitch])
        uiSwitchContainer.axis = .horizontal
        uiSwitchContainer.alignment = .center
        uiSwitchContainer.distribution = .fillProportionally
        return uiSwitchContainer
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