import UIKit
import UltraDrawerView
import Utils
import MapKit
import RxSwift
import RxCocoa

final class CardViewController: UIViewController {

    typealias ShapeCellConfigurator = CellConfigurator<ShapeCell, ShapeCellModel>

    enum Kind {
        case simple
        case smart
    }

    init(kind: Kind) {
        self.kind = kind
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(white: 0.9, alpha: 1.0)

        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(mapView.pinToParent())
        
        headerView = CardHeaderView()
        headerView.title = Constants.Header.headerTitle
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.heightAnchor.constraint(equalToConstant: Constants.Header.headerHeight).isActive = true
        headerView.onButtonTap = { [weak self] in
            self?.handleResetButton()
        }

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

        let strategy: DrawerHidingStrategy = {
            switch kind {
            case .simple:
                return SimpleDrawerHidingStrategy()
            case .smart:
                let smartStrategy = SmartDrawerHidingStrategy(timerScheduler: MainScheduler.instance,
                                                              timeInSeconds: 5)
                smartStrategy.timerTickHandler = { [weak self] timeRemains -> Void in
                    self?.headerView.title = "Закроется через \(timeRemains) сек"
                }
                smartStrategy.timerResetHandler = { [weak self] in
                    self?.headerView.title = Constants.Header.headerTitle
                }
                return smartStrategy
            }
        }()
        self.drawerHidingBehavior = DrawerHidingBehavior(
            drawerInput: drawerView,
            cameraManagerOutput: fakeCameraManager,
            locationManagerOutput: fakeLocationManager,
            strategy: strategy
        )
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

        drawerHidingBehavior.isOn = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        drawerHidingBehavior.isOn = false
    }
    
    // MARK: - Private

    private let mapView = MKMapView()
    private let tableView = UITableView()
    private var headerView: CardHeaderView!
    private var drawerView: DrawerView!
    private let shapesDataSource = TableViewDataSource()
    private var isFirstLayout = true
    private var portraitConstraints: [NSLayoutConstraint] = []
    private var landscapeConstraints: [NSLayoutConstraint] = []

    private let kind: Kind
    private var drawerHidingBehavior: DrawerHidingBehavior!
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
            static let headerTitle: String = "Карточка"
        }
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
        let settingsView = makeSpeedView(speed: fakeLocationManager.didUpdateSpeed)
        view.addSubview(settingsView)
        settingsView.translatesAutoresizingMaskIntoConstraints = false
        settingsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8.0).isActive = true
        settingsView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -8.0).isActive = true
    }

    func makeSpeedView(speed: Observable<Double>) -> UIView {
        let increaseSpeed = makeButton(withTitle: "+", action: #selector(handleSpeedUpButton))
        let decreaseSpeed = makeButton(withTitle: "-", action: #selector(handleSlowDownButton))
        let autoRotationSwitch = UISwitch()
        autoRotationSwitch.translatesAutoresizingMaskIntoConstraints = false
        _ = fakeCameraManager.isOn.bind(to: autoRotationSwitch.rx.isOn)
        autoRotationSwitch.addTarget(self, action: #selector(handleAutorotationSwitch), for: .valueChanged)
        autoRotationSwitch.tintColor = UIColor.darkGray

        let buttonsStackView = UIStackView(arrangedSubviews: [increaseSpeed, decreaseSpeed, autoRotationSwitch])
        buttonsStackView.axis = .vertical
        buttonsStackView.alignment = .fill
        buttonsStackView.spacing = 8.0
        buttonsStackView.distribution = .fillEqually

        let speedLabel = UILabel()
        speedLabel.font = .boldSystemFont(ofSize: UIFont.labelFontSize)
        speedLabel.textColor = .black
        speedLabel.textAlignment = .center
        speedLabel.numberOfLines = 1
        _ = speed.map { s -> String? in "\(s) м/с" }.bind(to: speedLabel.rx.text)


        let speedView = UIImageView()
        speedView.image = StyleKit.imageOfIntro_guidance_camera()
        speedView.addSubview(speedLabel)

        speedLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            speedLabel.centerXAnchor.constraint(equalTo: speedView.centerXAnchor),
            speedLabel.centerYAnchor.constraint(equalTo: speedView.centerYAnchor),
        ])

        speedView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            speedView.heightAnchor.constraint(equalToConstant: 112),
            speedView.widthAnchor.constraint(equalToConstant: 112)
        ])

        let stackView = UIStackView(arrangedSubviews: [speedView, buttonsStackView])
        stackView.axis = .horizontal

        let backgroundView = UIView()
        backgroundView.addSubview(stackView)
        backgroundView.backgroundColor = UIColor.gray.withAlphaComponent(0.2)
        backgroundView.layer.cornerRadius = 8.0
        backgroundView.layer.masksToBounds = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(stackView.pinToParent(withInsets: .all(8.0)))
        return backgroundView
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

    @objc private func handleResetButton() {
        drawerView.setState(UIDevice.current.orientation.isLandscape ? .top : .middle, animated: true)
        fakeLocationManager.speed.accept(0.0)
        fakeCameraManager.isOn.accept(false)
    }

    @objc private func handleSpeedUpButton() {
        fakeLocationManager.speed.accept(fakeLocationManager.speed.value + 1)
    }
    
    @objc private func handleSlowDownButton() {
        let newSpeed = fakeLocationManager.speed.value - 1
        fakeLocationManager.speed.accept(newSpeed >= 0 ? newSpeed : 0.0)
    }

    @objc private func handleAutorotationSwitch(_ sender: UISwitch) {
        fakeCameraManager.isOn.accept(sender.isOn)
    }
}
