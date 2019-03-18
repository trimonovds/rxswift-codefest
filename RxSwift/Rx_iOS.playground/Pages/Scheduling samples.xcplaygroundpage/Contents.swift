import UIKit
import RxSwift
import PlaygroundSupport
import Utils

func fib(_ n: Int) -> Int {
    guard n > 1 else { return n }
    return fib(n-1) + fib(n-2)
}

func calculateFibonacci(n: Int) -> Observable<Int> {
    return Observable<Int>.create { observer -> Disposable in
        logWithQueueInfo("subscribe")
        observer.onNext(fib(n))
        observer.onCompleted()
        return Disposables.create()
    }
}

//example("no subscribeOn") {
//    calculateFibonacci(n: 25)
//        .map { i -> Int in logWithQueueInfo("map"); return i * 2 }
//        .subscribe(onNext: { (num) in
//            logWithQueueInfo("onNext: \(num)")
//        })
//}

example("subscribeOn") {
    calculateFibonacci(n: 25)
        .map { i -> Int in logWithQueueInfo("map"); return i * 2 }
        .subscribeOn(SerialDispatchQueueScheduler(qos: .background))
        .subscribe(onNext: { (num) in
            logWithQueueInfo("onNext: \(num)")
        })
}


