//
//  ToDoDetailsSheetVС.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 05.09.2025.
//

import UIKit

final class ToDoDetailsSheetViewController: UIViewController {
    
    // MARK: Input
    private var model: ToDoDetailsModel
    
    // MARK: Callbacks
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    var onToggleDone: (() -> Void)? // оставлен для совместимости
    
    // MARK: UI
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let dimView = UIView()
    private let rootStack = UIStackView()
    
    // Карточка задачи (серый фон по макету)
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let dateLabel = UILabel()
    
    // Единый блок действий (светлый фон по макету)
    private let actionsContainer = UIView()
    private let actionsStack = UIStackView()
    
    // MARK: Init
    init(model: ToDoDetailsModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupBlur()
        setupLayout()
        bind(model)
    }
    
    private func actionIcon(named assetName: String, fallback systemName: String) -> UIImage {
        if let img = UIImage(named: assetName) {
            return img.withRenderingMode(.alwaysTemplate) // используем tintColor
        }
        let cfg = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        return UIImage(systemName: systemName, withConfiguration: cfg)!.withRenderingMode(.alwaysTemplate)
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
        
        // Доп. затемнение для “чёрного” вида
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
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        dimView.addGestureRecognizer(tap)
    }
    
    // MARK: Layout (размеры из макета)
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
        NSLayoutConstraint.activate([
            rootStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            rootStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -bottomInset)
        ])
        
        // Карточка задачи — СЕРЫЙ фон (AppColor.gray)
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
        
        // Тексты на тёмном фоне
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
        
        // Единый блок действий — СВЕТЛЫЙ фон
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
        
        // Строки действий: текст слева, иконка справа
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
        let row = UIControl()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 44).isActive = true
        row.addTarget(self, action: action, for: .touchUpInside)
        
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
        
        row.addSubview(titleLabel)
        row.addSubview(iconView)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            
            iconView.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -12),
            iconView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22)
        ])
        
        actionsStack.addArrangedSubview(row)
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
    
    // MARK: Actions
    @objc private func dismissSelf() { dismiss(animated: true) }
    @objc private func editTapped() {
        let run = onEdit
        dismiss(animated: true) {
            run?()   // открываем экран задачи ПОСЛЕ закрытия листа
        }
    }
    @objc private func shareTapped() {
        var items: [Any] = [model.title]
        if let text = model.details, !text.isEmpty { items.append(text) }
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(ac, animated: true)
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
}
