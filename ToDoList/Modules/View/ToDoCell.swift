//
//  ToDoCell.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 05.09.2025.
//

import UIKit

final class ToDoCell: UITableViewCell {
    static let reuseId = "ToDoCell"
    
    // Вызов при тапе по статусу
    var onToggleTapped: (() -> Void)?
    
    // UIButton для обработки тапа
    private let statusButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.tintColor = AppColor.yellow
        b.backgroundColor = .clear
        b.accessibilityIdentifier = "todo.statusButton"
        return b
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 1
        l.font = .systemFont(ofSize: 20, weight: .semibold)
        l.textColor = AppColor.white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let bodyLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 2
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.textColor = UIColor(white: 1, alpha: 0.85)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let dateLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 1
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = UIColor(white: 1, alpha: 0.6)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let separator: UIView = {
        let separatorView = UIView()
        separatorView.backgroundColor = AppColor.stroke
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        return separatorView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = AppColor.black
        contentView.backgroundColor = AppColor.black
        selectionStyle = .none
        tintColor = AppColor.yellow
        
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.attributedText = nil
        titleLabel.text = nil
        bodyLabel.text = nil
        dateLabel.text = nil
        onToggleTapped = nil
    }
    
    // конфигурация
    func configure(title: String, body: String?, date: String?, isDone: Bool) {
        if isDone {
            let doneTitleAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: AppColor.white,
                .strikethroughStyle: NSUnderlineStyle.single.rawValue
            ]
            titleLabel.attributedText = NSAttributedString(string: title, attributes: doneTitleAttributes)
        } else {
            titleLabel.text = title
        }
        
        bodyLabel.text = body
        dateLabel.text = date
        
        // Иконки статуса на кнопке
        let imageName = isDone ? "checkmark.circle.fill" : "circle"
        statusButton.setImage(UIImage(systemName: imageName), for: .normal)
        statusButton.accessibilityLabel = isDone ? "Отметить как не выполнено" : "Отметить как выполнено"
    }
    
    // MARK: - Actions
    @objc private func statusTapped() {
        onToggleTapped?()
    }
}
