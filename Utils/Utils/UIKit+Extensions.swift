//
//  UIKit+Extensions.swift
//  Utils
//
//  Created by Dmitry Trimonov on 18/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import UIKit

extension UIColor {
    public static var random: UIColor {
        let r = CGFloat(Int.random(in: 0...255)) / 255
        let g = CGFloat(Int.random(in: 0...255)) / 255
        let b = CGFloat(Int.random(in: 0...255)) / 255
        return UIColor.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
