//
//  ToDoDetailsSheetVС.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 05.09.2025.
//

import UIKit

final class ToDoDetailsSheetViewController: UIViewController {
    
    // MARK: - Public Properties
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    var onToggleDone: (() -> Void)?
    
    // MARK: - Private Properties
    private var model: ToDoDetailsModel
    
    // MARK: UI
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let dimView = UIView()
    private let rootStack = UIStackView()
    
    // Карточка задачи
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let dateLabel = UILabel()
    
    // Блок действий
    private let actionsContainer = UIView()
    private let actionsStack = UIStackView()
    
    // MARK: Init
    init(model: ToDoDetailsModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupBlur()
        setupLayout()
        bind(model)
    }
    
    // MARK: - IB Actions
    @objc private func dismissSelf() { dismiss(animated: true) }
    
    @objc private func editTapped() {
        let editCallback = onEdit
        dismiss(animated: true) {
            editCallback?()
        }
    }
    
    @objc private func shareTapped() {
        var items: [Any] = [model.title]
        if let text = model.details, !text.isEmpty { items.append(text) }
        let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(activityController, animated: true)
    }
    
    @objc private func deleteTapped() {
        let alert = UIAlertController(title: "Удалить задачу?", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.onDelete?()
            self?.dismissSelf()
        })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Private Methods
    private func actionIcon(named assetName: String, fallback systemName: String) -> UIImage {
        if let image = UIImage(named: assetName) {
            return image.withRenderingMode(.alwaysTemplate) // используем tintColor
        }
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        return UIImage(systemName: systemName, withConfiguration: config)!.withRenderingMode(.alwaysTemplate)
    }
    
    // MARK: Blur
    private func setupBlur() {
        // Blur
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Доп. затемнение
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        dimView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimView)
        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Тап по фону — закрыть
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        dimView.addGestureRecognizer(tapRecognizer)
    }
    
    // MARK: Layout
    private func setupLayout() {
        let cardWidth: CGFloat = 320
        let cardHeight: CGFloat = 106
        let actionsWidth: CGFloat = 254
        let cornerRadius: CGFloat = 12
        let bottomInset: CGFloat = 150
        
        // Корневой стек
        rootStack.axis = .vertical
        rootStack.alignment = .center
        rootStack.spacing = 16
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)
        NSLayoutConstraint.activate(
            [
                rootStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                rootStack.bottomAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                    constant: -bottomInset
                )
            ]
        )
        
        // Карточка задачи
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = AppColor.gray
        cardView.layer.cornerRadius = cornerRadius
        cardView.layer.masksToBounds = true
        rootStack.addArrangedSubview(cardView)
        NSLayoutConstraint.activate([
            cardView.widthAnchor.constraint(equalToConstant: cardWidth),
            cardView.heightAnchor.constraint(equalToConstant: cardHeight)
        ])
        
        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.spacing = 6
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(cardStack)
        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            cardStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            cardStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            cardStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12)
        ])
        
        titleLabel.numberOfLines = 1
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = AppColor.white
        
        bodyLabel.numberOfLines = 2
        bodyLabel.font = .systemFont(ofSize: 15)
        bodyLabel.textColor = UIColor(white: 1.0, alpha: 0.85)
        
        dateLabel.numberOfLines  = 1
        dateLabel.font = .systemFont(ofSize: 13)
        dateLabel.textColor = UIColor(white: 1.0, alpha: 0.60)
        
        cardStack.addArrangedSubview(titleLabel)
        cardStack.addArrangedSubview(bodyLabel)
        cardStack.addArrangedSubview(dateLabel)
        
        // Блок действий
        actionsContainer.translatesAutoresizingMaskIntoConstraints = false
        actionsContainer.backgroundColor = UIColor(white: 0.96, alpha: 1.0)
        actionsContainer.layer.cornerRadius = cornerRadius
        actionsContainer.clipsToBounds = true
        rootStack.addArrangedSubview(actionsContainer)
        NSLayoutConstraint.activate([
            actionsContainer.widthAnchor.constraint(equalToConstant: actionsWidth)
        ])
        
        actionsStack.axis = .vertical
        actionsStack.translatesAutoresizingMaskIntoConstraints = false
        actionsContainer.addSubview(actionsStack)
        NSLayoutConstraint.activate([
            actionsStack.topAnchor.constraint(equalTo: actionsContainer.topAnchor),
            actionsStack.leadingAnchor.constraint(equalTo: actionsContainer.leadingAnchor),
            actionsStack.trailingAnchor.constraint(equalTo: actionsContainer.trailingAnchor),
            actionsStack.bottomAnchor.constraint(equalTo: actionsContainer.bottomAnchor)
        ])
        
        addActionRow(
            title: "Редактировать",
            imageName: "action_edit",
            sfFallback: "square.and.pencil",
            isDestructive: false,
            action: #selector(editTapped)
        )
        addSeparator()
        addActionRow(
            title: "Поделиться",
            imageName: "action_share",
            sfFallback: "square.and.arrow.up",
            isDestructive: false,
            action: #selector(shareTapped)
        )
        addSeparator()
        addActionRow(
            title: "Удалить",
            imageName: "action_delete",
            sfFallback: "trash",
            isDestructive: true,
            action: #selector(deleteTapped)
        )
    }
    
    // MARK: Action rows
    private func addActionRow(
        title: String,
        imageName: String,
        sfFallback: String,
        isDestructive: Bool,
        action: Selector
    ) {
        let actionRow = UIControl()
        actionRow.translatesAutoresizingMaskIntoConstraints = false
        actionRow.heightAnchor.constraint(equalToConstant: 44).isActive = true
        actionRow.addTarget(self, action: action, for: .touchUpInside)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17)
        titleLabel.textColor = isDestructive ? .systemRed : UIColor(white: 0.05, alpha: 1.0)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let iconView = UIImageView()
        iconView.image = actionIcon(named: imageName, fallback: sfFallback)
        iconView.tintColor = isDestructive ? .systemRed : UIColor(white: 0.05, alpha: 1.0)
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        
        actionRow.addSubview(titleLabel)
        actionRow.addSubview(iconView)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: actionRow.leadingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: actionRow.centerYAnchor),
            
            iconView.trailingAnchor.constraint(equalTo: actionRow.trailingAnchor, constant: -12),
            iconView.centerYAnchor.constraint(equalTo: actionRow.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22)
        ])
        
        actionsStack.addArrangedSubview(actionRow)
    }
    
    private func addSeparator() {
        let separator = UIView()
        separator.backgroundColor = UIColor(white: 0.80, alpha: 1.0)
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        actionsStack.addArrangedSubview(separator)
    }
    
    // MARK: Bind
    private func bind(_ model: ToDoDetailsModel) {
        titleLabel.text = model.title
        bodyLabel.text = model.details
        dateLabel.text = model.dateText
    }
}
