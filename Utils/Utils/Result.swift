//
//  Result.swift
//  Utils
//
//  Created by Dmitry Trimonov on 21/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import Foundation

public enum Result<T> {
    case success(T)
    case error(Error)
}
