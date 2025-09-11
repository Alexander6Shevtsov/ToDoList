//
//  AppTheme.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 03.09.2025.
//

import UIKit

// MARK: - AppColor
enum AppColor {
    static let black  = UIColor(
        red: 0x04/255.0,
        green: 0x04/255.0,
        blue: 0x04/255.0,
        alpha: 1
    )
    static let white  = UIColor(
        red: 0xF4/255.0,
        green: 0xF4/255.0,
        blue: 0xF4/255.0,
        alpha: 1
    )
    static let yellow = UIColor(
        red: 0xFE/255.0,
        green: 0xD7/255.0,
        blue: 0x02/255.0,
        alpha: 1
    )
    static let stroke = UIColor(
        red: 0x4D/255.0,
        green: 0x55/255.0,
        blue: 0x5E/255.0,
        alpha: 1
    )
    static let gray   = UIColor(
        red: 0x27/255.0,
        green: 0x27/255.0,
        blue: 0x29/255.0,
        alpha: 1
    )
    static let red    = UIColor(
        red: 0xD7/255.0,
        green: 0x00/255.0,
        blue: 0x15/255.0,
        alpha: 1
    )
}

// MARK: - AppFont
enum AppFont {
    static func title() -> UIFont { .preferredFont(forTextStyle: .headline) }
    static func subtitle() -> UIFont { .preferredFont(forTextStyle: .subheadline) }
    static func meta() -> UIFont { .preferredFont(forTextStyle: .caption1) }
}

// MARK: - Theme add-on
extension AppColor {
    static let background: UIColor = .black
    static let surface: UIColor = UIColor(white: 0.16, alpha: 1.0)
}
