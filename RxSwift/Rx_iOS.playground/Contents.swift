import UIKit
import Utils
import RxSwift
import RxCocoa
import PlaygroundSupport

struct SomeError: Error { }

class CountryCell: TableViewCell {
    typealias Model = Country
    func bind(to model: CountryCell.Model) {
        self.textLabel?.text = model.name
    }
}

struct Country {
    let name: String
}

protocol CountriesRepository {
    func fetchCountries() -> Observable<[Country]>
}

class CountriesViewController: UIViewController, UITableViewDelegate {

    typealias CountryCellConfigurator = CellConfigurator<CountryCell, Country>


    let tableView: UITableView = UITableView()
    let searchBar: UISearchBar = UISearchBar()

    init(repo: CountriesRepository) {
        self.repo = repo
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.dataSource = dataSource
        tableView.delegate = self

        view.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate(
            tableView.pinToParentSafe(withEdges: [.bottom, .left, .right]) +
                searchBar.pinToParentSafe(withEdges: [.top, .left, .right]) +
                [tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor)]
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let countriesStream = repo.fetchCountries().startWith([])
        countriesStream.subscribe(onNext: { [weak self] countries in
            guard let slf = self else { return }
            slf.updateDataSource(with: countries)
            slf.tableView.reloadData()
        })
        countriesStream.map { $0.count }
            .subscribe({ [weak self] event in
                guard let slf = self else { return }
                switch event {
                case .next(let countriesCount):
                    slf.searchBar.placeholder = "\(countriesCount) countries"
                case .error(_):
                    slf.searchBar.placeholder = "Can't load countries"
                case .completed:
                    return
                }
            })
    }

    func updateDataSource(with countries: [Country]) {
        dataSource.sectionConfigurations = [
            SectionConfigurator(cellConfigurators: countries.map { CountryCellConfigurator(model: $0) })
        ]
    }

    private let repo: CountriesRepository
    private let dataSource = TableViewDataSource()
}

class CountriesRepositoryImpl: CountriesRepository {
    func fetchCountries() -> Observable<[Country]> {
        return Observable.create({ (observer) -> Disposable in
            let fakeCountries = [
                Country(name: "Russia"),
                Country(name: "USA"),
                Country(name: "Austria"),
                Country(name: "France")
            ]
            let random = Int.random(in: (0...2))
            if random == 2 {
                observer.on(.error(SomeError()))
                observer.on(.completed)
            } else {
                observer.on(.next(fakeCountries))
                observer.on(.completed)
            }
            return Disposables.create { }
        })
    }
}

PlaygroundPage.current.liveView = CountriesViewController(repo: CountriesRepositoryImpl())
