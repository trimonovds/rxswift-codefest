//: [Previous](@previous)

import UIKit
import RxKit
import Utils
import PlaygroundSupport

struct Country {
    let name: String
}

class CountryCell: TableViewCell {
    typealias Model = Country
    func bind(to model: CountryCell.Model) {
        self.textLabel?.text = model.name
    }
}

protocol CountriesRepository {
    func fetchCountries() -> Observable<[Country]>
}

struct CountriesModel {
    let countries: [Country]
}

class CountriesViewController: UIViewController {

    typealias CountryCellConfigurator = CellConfigurator<CountryCell, Country>

    var model: CountriesModel? {
        didSet {
            guard let m = model else {
                dataSource.sectionConfigurations = []
                tableView.reloadData()
                return
            }
            dataSource.sectionConfigurations = [
                SectionConfigurator(cellConfigurators: m.countries.map { CountryCellConfigurator(model: $0) })
            ]
            tableView.reloadData()
        }
    }

    var tableView: UITableView!

    init(repo: CountriesRepository) {
        self.repo = repo
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView = UITableView()
        tableView.rowHeight = UITableView.automaticDimension
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        tableView.dataSource = dataSource
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        repo.fetchCountries().subscribe(onNext: {
            self.model = CountriesModel(countries: $0)
        })
    }

    private let repo: CountriesRepository
    private let dataSource = TableViewDataSource()
}

class CountriesRepositoryImpl: CountriesRepository {
    func fetchCountries() -> Observable<[Country]> {
        let fakeCountries = [
            Country(name: "Russia")
        ]
        return Observable<[Country]>.just(element: fakeCountries)
    }
}

PlaygroundPage.current.liveView = CountriesViewController(repo: CountriesRepositoryImpl())

//: [Next](@next)


