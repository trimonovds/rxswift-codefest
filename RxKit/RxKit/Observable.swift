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

public enum Event<T> {
    case success(T)
    case error(Error)
    case completed
}

public protocol Observer {
    associatedtype T
    func on(_ event: Event<T>)
}

public protocol Observable {
    associatedtype T
    func subscribe<O: Observer>(_ observer: O) -> Disposable where O.T == T
}
