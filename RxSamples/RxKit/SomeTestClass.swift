//
//  SomeTestClass.swift
//  RxKit
//
//  Created by Dmitry Trimonov on 03/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import Foundation
import RxSwift

public class SomeSampleClass {
    public static let shared = SomeSampleClass()

    public func doSmth() {
        Observable<Int>
            .from([1,2,3,4,6])
            .duplicate()
            .subscribe(onNext: { (x) in
                print(x)
            })
    }
}
