//
//  Disposables.swift
//  RxKit
//
//  Created by Dmitry Trimonov on 09/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import Foundation

public class Disposables {
    class BlockDisposable: Disposable {

        private let block: () -> Void

        init(block: @escaping () -> Void) {
            self.block = block
        }

        func dispose() {
            block()
        }
    }

    public static func empty() -> Disposable {
        return BlockDisposable(block: { })
    }

    public static func create(block: @escaping () -> Void) -> Disposable {
        return BlockDisposable(block: block)
    }
}
