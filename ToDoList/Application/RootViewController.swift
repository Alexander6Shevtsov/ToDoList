//
//  RootViewController.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 29.08.2025.
//

import UIKit

final class RootViewController: UIViewController {
    
    // MARK: - Private Properties
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Boot OK"
        label.textAlignment = .center
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
        setupViewHierarchy()
        setupConstraints()
    }
    
    // MARK: - Private Methods
    private func configureAppearance() {
        view.backgroundColor = UIColor(hex: 0x121212)
    }
    
    private func setupViewHierarchy() {
        view.addSubview(statusLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

// MARK: - Private Helpers
private extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
