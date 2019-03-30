import UIKit
import RxSwift
import PlaygroundSupport
import Utils

class PrintObserver<T>: ObserverType {
    typealias E = T
    func on(_ event: Event<T>) { log("PrintObserver<\(T.self)> did receive: \(event)") }
    deinit { log("PrintObserver<\(T.self)> deallocated") }
}

example("BehaviorSubject behavior") {
    let subject = BehaviorSubject<Bool>(value: false)
    subject.onCompleted()
    _ = subject.subscribe(PrintObserver<Bool>())
    subject.onNext(true)
    subject.onNext(false)
}

example("PublishSubject behavior") {
    let subject = PublishSubject<Bool>()
    subject.onCompleted()
    _ = subject.subscribe(PrintObserver<Bool>())
    subject.onNext(true)
    subject.onNext(false)
}




