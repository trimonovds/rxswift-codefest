//: [Previous](@previous)

import UIKit
import RxKit
import Utils
import PlaygroundSupport

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

        let countriesStream = repo.fetchCountries().startWith(element: [])
        countriesStream.subscribe(onNext: { countries in
            self.updateDataSource(with: countries)
            self.tableView.reloadData()
        })
        countriesStream.map { $0.count }
            .subscribe(onNext: { countriesCount in
                self.searchBar.placeholder = "\(countriesCount) countries"
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
        let fakeCountries = [
            Country(name: "Russia"),
            Country(name: "USA"),
            Country(name: "Austria"),
            Country(name: "France")
        ]
        return Observable<[Country]>.just(element: fakeCountries)
    }
}

PlaygroundPage.current.liveView = CountriesViewController(repo: CountriesRepositoryImpl())

//: [Next](@next)


