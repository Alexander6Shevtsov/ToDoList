//
//  TaskEditorViewController.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 05.09.2025.
//

import UIKit

enum TaskEditorMode {
    case create
    case edit(id: Int)
}

final class TaskEditorViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {
    
    // MARK: Public
    var onSave: ((String, String?) -> Void)?
    
    private let mode: TaskEditorMode
    private let dateText: String
    
    private let originalTitle: String
    private let originalDetails: String
    
    // MARK: Button "Сохранить"
    private lazy var saveButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(
            title: "Сохранить",
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
        item.tintColor = AppColor.yellow
        return item
    }()
    
    private lazy var barBackButton: UIButton = {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.setTitle(" Назад", for: .normal)
        backButton.tintColor = AppColor.yellow
        backButton.setTitleColor(AppColor.yellow, for: .normal)
        backButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        backButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return backButton
    }()
    
    init(mode: TaskEditorMode, title: String?, details: String?, dateText: String) {
        self.mode = mode
        self.dateText = dateText
        self.originalTitle = title ?? ""
        self.originalDetails = details ?? ""
        super.init(nibName: nil, bundle: nil)
        titleTextField.text = title
        bodyTextView.text = details
        applyPlaceholdersIfNeeded()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: UI
    private let scrollView = UIScrollView()
    private let content = UIStackView()
    
    private let titleTextField: UITextField = {
        let title = UITextField()
        title.font = .systemFont(ofSize: 34, weight: .bold)
        title.textColor = AppColor.white
        title.tintColor = AppColor.yellow
        title.placeholder = "Название"
        title.translatesAutoresizingMaskIntoConstraints = false
        return title
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = UIColor(white: 1, alpha: 0.6)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let bodyTextView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.textColor = AppColor.white
        textView.tintColor = AppColor.yellow
        textView.font = .systemFont(ofSize: 20, weight: .regular)
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private let bottomSpacer = UIView()
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        overrideUserInterfaceStyle = .dark
        view.backgroundColor = AppColor.background
        
        navigationItem.title = nil
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.leftBarButtonItem  = UIBarButtonItem(
            customView: barBackButton
        )
        
        titleTextField.addTarget(
            self,
            action: #selector(textEditingChanged),
            for: .editingChanged
        )
        
        updateSaveVisibility()
        setupLayout()
        bind()
        addKeyboardObservers()
        
        titleTextField.delegate = self
        bodyTextView.delegate = self
        titleTextField.becomeFirstResponder()
    }
    
    deinit { NotificationCenter.default.removeObserver(self) }
    
    // MARK: Layout
    private func setupLayout() {
        // Scroll
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Контейнер
        content.axis = .vertical
        content.spacing = 16
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            content.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor)
        ])
        
        // Шапка: Заголовок + Дата
        let headerStack = UIStackView()
        headerStack.axis = .vertical
        headerStack.spacing = 4
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerStack.addArrangedSubview(titleTextField)
        headerStack.addArrangedSubview(dateLabel)
        content.addArrangedSubview(headerStack)
        
        // Текст задачи
        content.addArrangedSubview(bodyTextView)
        bodyTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 240).isActive = true
        
        // Нижний спейсер
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        bottomSpacer.heightAnchor.constraint(equalToConstant: 0).isActive = true
        content.addArrangedSubview(bottomSpacer)
    }
    
    private func bind() {
        dateLabel.text = dateText
    }
    
    // MARK: Actions
    @objc private func closeTapped() { dismissOrPop() }
    
    @objc private func saveTapped() {
        let title = titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let details = bodyTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { titleTextField.becomeFirstResponder(); return }
        onSave?(title, (details?.isEmpty == true) ? nil : details)
        dismissOrPop()
    }
    
    private func dismissOrPop() {
        if let nav = navigationController, nav.viewControllers.first != self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    @objc private func textEditingChanged() { updateSaveVisibility() }
    func textViewDidChange(_ textView: UITextView) { updateSaveVisibility() }
    
    private func normalizedDetails() -> String {
        (bodyTextView.text == bodyPlaceholder) ? "" : (bodyTextView.text ?? "")
    }
    
    private func updateSaveVisibility() {
        let curTitle = titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let curDetails = normalizedDetails()
        
        switch mode {
        case .create:
            navigationItem.rightBarButtonItem = saveButtonItem
            saveButtonItem.isEnabled = !curTitle.isEmpty
        case .edit:
            let changed = (curTitle != originalTitle) || (curDetails != originalDetails)
            navigationItem.rightBarButtonItem = changed ? saveButtonItem : nil
            saveButtonItem.isEnabled = !curTitle.isEmpty
        }
    }
    
    // MARK: Placeholders
    private let bodyPlaceholder = "Описание"
    private func applyPlaceholdersIfNeeded() {
        if (bodyTextView.text ?? "").isEmpty {
            bodyTextView.text = bodyPlaceholder
            bodyTextView.textColor = UIColor(white: 1, alpha: 0.35)
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == bodyPlaceholder {
            textView.text = nil
            textView.textColor = AppColor.white
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if (textView.text ?? "").isEmpty {
            applyPlaceholdersIfNeeded()
        }
    }
    
    // MARK: Keyboard
    private func addKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardFrameChange),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }
    
    // MARK: - Keyboard
    @objc private func handleKeyboardFrameChange(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }
        
        // Переводим фрейм клавиатуры в координаты текущего view
        let keyboardEndFrameScreen = frameValue.cgRectValue
        let keyboardEndFrameInView = view.convert(keyboardEndFrameScreen, from: nil)
        let intersection = view.bounds.intersection(keyboardEndFrameInView)
        let bottomInset = max(0, intersection.height - view.safeAreaInsets.bottom)
        
        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)
        UIView.animate(withDuration: duration, delay: 0, options: options) { [weak self] in
            guard let self = self else { return }
            self.scrollView.contentInset.bottom = bottomInset
            self.scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
            self.view.layoutIfNeeded()
        }
    }
}
