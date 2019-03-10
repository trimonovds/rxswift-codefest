//
//  Just.swift
//  RxKit
//
//  Created by Dmitry Trimonov on 09/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import Foundation

extension IObservable {
    public static func just(element: Element) -> Observable<Element> {
        return JustObservable(element: element)
    }
}

final class JustObservable<T>: Observable<T> {

    private let element: T

    init(element: T) {
        self.element = element
        super.init()
    }

    override func subscribe<O>(_ observer: O) -> Disposable where T == O.Element, O : IObserver {
        observer.on(.next(element))
        observer.on(.completed)
        return Disposables.empty()
    }
}
