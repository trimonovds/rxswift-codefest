import RxKit
import UIKit

struct SomeError: Error { }

Observable.just(element: 3)
    .filter(predicate: { $0 > 0 })
    .subscribe(onNext: { print($0) })

print("----")

Observable.from(elements: [100, -12, 15, -17])
    .filter(predicate: { $0 < 0 })
    .map { $0 - 13 }
    .subscribe(onNext: { print($0) })

print("----")

Observable
    .create(subscribe: { (observer: (Event<Int>) -> Void) -> Disposable in
        observer(.next(3))
        observer(.next(5))
        observer(.completed)
        observer(.next(121))
        return Disposables.empty()
    })
    .subscribe(onNext: { print($0) })

print("----")

Observable
    .create(subscribe: { (observer: (Event<Int>) -> Void) -> Disposable in
        observer(.next(100))
        observer(.error(SomeError()))
        observer(.next(11))
        observer(.completed)
        return Disposables.empty()
    })
    .subscribe(onNext: { print($0) })
