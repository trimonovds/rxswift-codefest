//: [Previous](@previous)

import Foundation
import RxSwift

class PrintObserver<T>: ObserverType {
    typealias E = T
    let name: String
    init(name: String) {
        self.name = name
    }
    func on(_ event: Event<T>) {
        print(event)
    }
    deinit {
        print("PrintObserver<\(T.self)> called: \(name) deallocated")
    }
}

func puts<T>(t: T) {
    print(t)
}

func printResourcesTotal() {
    print("Resource.total: \(Resources.total)")
}

//example("JustLifecycle") {
//    let ticks = Observable<Int>.just(3)
//    printResourcesTotal()
//    let subscription = ticks.subscribe(onNext: puts)
//    printResourcesTotal()
//    Thread.sleep(forTimeInterval: 2.0)
//    print("Bye-bye example")
//    printResourcesTotal()
//}
//print("After example")
//printResourcesTotal()

example("JustLifecycleWhenDispose") {
    let ticks = Observable<Int>.just(3)
    printResourcesTotal()
    let subscription = ticks.subscribe(onNext: puts)
    printResourcesTotal()
    Thread.sleep(forTimeInterval: 2.0)
    subscription.dispose()
    print("Bye-bye example")
    printResourcesTotal()
}
print("After example")
printResourcesTotal()

//example("IntervalLifecycle") {
//    let ticks = Observable<Int>.interval(1.0, scheduler: MainScheduler.instance)
//    printResourcesTotal()
//    let subscription = ticks.subscribe(onNext: puts)
//    printResourcesTotal()
//    Thread.sleep(forTimeInterval: 2.0)
//    subscription.dispose()
//    print("Bye-bye example")
//    printResourcesTotal()
//}
//print("After example")
//printResourcesTotal()



