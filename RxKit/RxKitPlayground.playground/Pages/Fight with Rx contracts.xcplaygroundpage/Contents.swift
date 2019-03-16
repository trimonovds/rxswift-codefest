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

struct CountriesModel {
    let countries: [Country]
}

class CountriesViewController: UIViewController, UITableViewDelegate {

    typealias CountryCellConfigurator = CellConfigurator<CountryCell, Country>

    var model: CountriesModel! {
        didSet {
            dataSource.sectionConfigurations = [
                SectionConfigurator(cellConfigurators: model.countries.map { CountryCellConfigurator(model: $0) })
            ]
            tableView.reloadData()
        }
    }

    var tableView: UITableView!
    var searchBar: UISearchBar!

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
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.dataSource = dataSource
        tableView.delegate = self

        searchBar = UISearchBar()
        view.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate(
            tableView.pinToParentSafe(withEdges: [.bottom, .left, .right]) +
            searchBar.pinToParentSafe(withEdges: [.top, .left, .right]) +
            [tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor)]
        )

        model = CountriesModel(countries: [])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        repo.fetchCountries().subscribe(onNext: {
            self.update(withNewCountries: $0)
        })
    }

    func update(withNewCountries countries: [Country]) {
        self.model = CountriesModel(countries: countries)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let selectedCountyName = model?.countries[indexPath.row].name else { return }
        let alertVc = UIAlertController(title: "Wow", message: "\(selectedCountyName) chosen!", preferredStyle: .alert)
        alertVc.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            alertVc.dismiss(animated: true, completion: nil)
        }))

        self.present(alertVc, animated: true, completion: nil)
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


