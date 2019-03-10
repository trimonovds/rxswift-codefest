import RxKit

var str = "Hello, playground"

Observable.just(element: 3).filter(predicate: { $0 > 0 }).subscribe(onNext: { print($0) })
Observable.from(elements: [100, -12, 15, -17])
    .filter(predicate: { $0 < 0 })
    .map { $0 - 13 }
    .subscribe(onNext: { print($0) })


Observable
    .create(subscribe: { (observer: (Event<Int>) -> Void) -> Disposable in
        observer(.success(3))
        observer(.success(5))
        observer(.completed)
        observer(.success(121))
        return Disposables.empty()
    })
    .subscribe(onNext: { print($0) })
