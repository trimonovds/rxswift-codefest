//
//  Observable.swift
//  RxKit
//
//  Created by Dmitry Trimonov on 09/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import Foundation

public protocol Disposable: AnyObject {
    func dispose()
}

public enum Event<Element> {
    case success(Element)
    case error(Error)
    case completed
}

public protocol IObserver {
    associatedtype Element
    func on(_ event: Event<Element>)
}

public protocol IObservable: IObservableConverible {
    func subscribe<O: IObserver>(_ observer: O) -> Disposable where O.Element == Element
}

public protocol IObservableConverible {
    associatedtype Element
    func asObservable() -> Observable<Element>
}
