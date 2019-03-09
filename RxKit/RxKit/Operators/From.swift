//
//  From.swift
//  RxKit
//
//  Created by Dmitry Trimonov on 09/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import Foundation

extension IObservable {
    public static func from(elements: [Element]) -> Observable<Element> {
        return FromObservable(elements: elements)
    }
}

final class FromObservable<T>: Observable<T> {

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
