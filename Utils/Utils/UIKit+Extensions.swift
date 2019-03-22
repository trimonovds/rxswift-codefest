//
//  UIKit+Extensions.swift
//  Utils
//
//  Created by Dmitry Trimonov on 18/03/2019.
//  Copyright © 2019 Dmitry Trimonov. All rights reserved.
//

import UIKit


extension UIColor {

    public convenience init(rgb value: UInt) {
        self.init(byteRed: UInt8((value >> 16) & 0xff),
                  green: UInt8((value >> 8) & 0xff),
                  blue: UInt8(value & 0xff),
                  alpha: 0xff)
    }

    public convenience init(rgba value: UInt) {
        self.init(byteRed: UInt8((value >> 24) & 0xff),
                  green: UInt8((value >> 16) & 0xff),
                  blue: UInt8((value >> 8) & 0xff),
                  alpha: UInt8(value & 0xff))
    }

    public convenience init(byteRed red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8 = 0xff) {
        self.init(red: CGFloat(red) / 255.0,
                  green: CGFloat(green) / 255.0,
                  blue: CGFloat(blue) / 255.0,
                  alpha: CGFloat(alpha) / 255.0)
    }

    public static var random: UIColor {
        return UIColor(red: randComponent(), green: randComponent(), blue: randComponent(), alpha: 1.0)
    }

    public static func randComponent() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}


extension UIEdgeInsets {
    public static func all(_ value: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: value, left: value, bottom: value, right: value)
    }
}
