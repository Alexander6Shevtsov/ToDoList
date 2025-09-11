//
//  ToDoCell.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 05.09.2025.
//

import UIKit

final class ToDoCell: UITableViewCell {
    
    // MARK: - Public Properties
    static let reuseId = "ToDoCell"
    var onToggleTapped: (() -> Void)?
    
    // MARK: - Private Properties
    private let statusButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = AppColor.yellow
        button.backgroundColor = .clear
        button.accessibilityIdentifier = "todo.statusButton"
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = AppColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let bodyLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = UIColor(white: 1, alpha: 0.85)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor(white: 1, alpha: 0.6)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let separator: UIView = {
        let separatorView = UIView()
        separatorView.backgroundColor = AppColor.stroke
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        return separatorView
    }()
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = AppColor.background
        contentView.backgroundColor = AppColor.background
        selectionStyle = .none
        
        contentView.addSubview(statusButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(bodyLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(separator)
        
        NSLayoutConstraint.activate([
            statusButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statusButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            statusButton.widthAnchor.constraint(equalToConstant: 32),
            statusButton.heightAnchor.constraint(equalToConstant: 32),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: statusButton.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            bodyLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            dateLabel.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 6),
            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            separator.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        statusButton.addTarget(self, action: #selector(statusTapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Overrides
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.attributedText = nil
        bodyLabel.alpha = 1.0
        dateLabel.alpha = 0.8
        onToggleTapped = nil
    }
    
    // MARK: - Configure
    func configure(title: String, body: String?, date: String, isDone: Bool) {
        titleLabel.attributedText = makeTitleAttributed(text: title, isDone: isDone) // зачёркивание
        
        // Приглушение выполненной задачи
        bodyLabel.text = body
        bodyLabel.alpha = isDone ? 0.6 : 1.0
        
        dateLabel.text = date
        dateLabel.alpha = isDone ? 0.6 : 0.8
        
        // Иконка статуса
        let imageName = isDone ? "checkmark.circle.fill" : "circle"
        statusButton.setImage(UIImage(systemName: imageName), for: .normal)
        statusButton.accessibilityLabel = isDone ? "Отметить как не выполнено" : "Отметить как выполнено"
    }
    
    // MARK: - Actions
    @objc private func statusTapped() {
        onToggleTapped?()
    }
    
    // MARK: - Private Methods
    // Зачёркивание
    private func makeTitleAttributed(text: String, isDone: Bool) -> NSAttributedString {
        let baseColor: UIColor = titleLabel.textColor ?? .label
        let baseFont: UIFont = titleLabel.font ?? .systemFont(ofSize: 20, weight: .semibold)
        
        if isDone {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: baseFont,
                .foregroundColor: baseColor.withAlphaComponent(0.7),
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .strikethroughColor: baseColor
            ]
            return NSAttributedString(string: text, attributes: attributes)
        } else {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: baseFont,
                .foregroundColor: baseColor
            ]
            return NSAttributedString(string: text, attributes: attributes)
        }
    }
}
