//: [Previous](@previous)

import UIKit
import Utils
import RxSwift
import RxCocoa
import PlaygroundSupport

public class TimeInfoView: UIView {
    public var date: Date = Date() {
        didSet {
            update(withNew: date)
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(dateLabel)
        addSubview(timeLabel)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            dateLabel.pinToParent(withEdges: [.left, .top, .right]) +
                timeLabel.pinToParent(withEdges: [.left, .bottom, .right]) +
                [
                    timeLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8.0)
            ]
        )
        dateLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        timeLabel.font = UIFont.preferredFont(forTextStyle: .caption2)
        dateLabel.textColor = .black
        timeLabel.textColor = .gray

        date = Date()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func update(withNew date: Date) {
        let dateString = DateFormatter.localizedString(from: date, dateStyle: .full, timeStyle: .none)
        let timeString = DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .medium)
        dateLabel.text = "Дата: \(dateString)"
        timeLabel.text = "Время: \(timeString)"
    }

    private let dateLabel = UILabel()
    private let timeLabel = UILabel()
}

extension Reactive where Base: TimeInfoView {

    /// Bindable sink for `state` property.
    public var date: Binder<Date> {
        return Binder(self.base) { element, value in
            element.date = value
        }
    }
}

class TimeInfoViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        let timeInfoView = TimeInfoView(frame: .zero)
        timeInfoView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timeInfoView)

        NSLayoutConstraint.activate(
            timeInfoView.centerInParent(.vertically) +
                timeInfoView.centerInParent(.horizontally)
        )

        Observable<Int>
            .interval(1.0, scheduler: MainScheduler.instance)
            .map { _ in () }
            .startWith(())
            .map { Date() }
            .bind(to: timeInfoView.rx.date)
    }

    private let bag = DisposeBag()
}

PlaygroundPage.current.liveView = TimeInfoViewController()

//: [Next](@next)
