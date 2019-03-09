import UIKit
import RxKit

var str = "Hello, playground"

class Disposables {
    class BlockDisposable: Disposable {

        private let block: () -> Void

        init(block: @escaping () -> Void) {
            self.block = block
        }

        func dispose() {
            block()
        }
    }

    static func empty() -> Disposable {
        return BlockDisposable(block: { })
    }
}

class JustObservable<T>: Observable<T> {

    private let element: T

    init(element: T) {
        self.element = element
        super.init()
    }

    override func subscribe<O>(_ observer: O) -> Disposable where T == O.Element, O : IObserver {
        observer.on(.success(element))
        observer.on(.completed)
        return Disposables.empty()
    }
}

class FromObservable<T>: Observable<T> {

    private let elements: [T]

    init(elements: [T]) {
        self.elements = elements
        super.init()
    }

    override func subscribe<O>(_ observer: O) -> Disposable where T == O.Element, O : IObserver {
        for el in elements {
            observer.on(.success(el))
        }
        observer.on(.completed)
        return Disposables.empty()
    }
}

extension IObservable {
    static func just(element: Element) -> Observable<Element> {
        return JustObservable(element: element)
    }
}

extension IObservable {
    static func from(elements: [Element]) -> Observable<Element> {
        return FromObservable(elements: elements)
    }
}

class BlockObserver<T>: IObserver {
    typealias Element = T

    private let onNext: (T) -> Void

    init(onNext: @escaping (T) -> Void) {
        self.onNext = onNext
    }

    func on(_ event: Event<T>) {
        switch event {
        case .success(let value):
            onNext(value)
        default:
            break
        }
    }
}

Observable.just(element: 3).filter(predicate: { $0 < 0 }).subscribe(BlockObserver { print($0) })
Observable.from(elements: [3, -12, 15, -17]).filter(predicate: { $0 < 0 }).subscribe(BlockObserver { print($0) })
