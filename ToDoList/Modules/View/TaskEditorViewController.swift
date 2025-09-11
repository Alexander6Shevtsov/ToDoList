//
//  TaskEditorViewController.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 05.09.2025.
//

import UIKit

// Редактор
enum TaskEditorMode {
    case create
    case edit(id: Int)
}

final class TaskEditorViewController: UIViewController {
    
    // MARK: - Public Properties
    /// Save
    var onSave: ((String, String?) -> Void)?
    
    // MARK: - Private Properties
    private let mode: TaskEditorMode
    private let dateText: String
    private let originalTitle: String
    private let originalDetails: String
    
    // UI
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    private let titleTextField: UITextField = {
        let field = UITextField()
        field.font = .systemFont(ofSize: 34, weight: .bold)
        field.textColor = AppColor.white
        field.tintColor = AppColor.yellow
        field.placeholder = "Название"
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
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
    
    // MARK: - Init
    init(mode: TaskEditorMode, title: String?, details: String?, dateText: String) {
        self.mode = mode
        self.dateText = dateText
        self.originalTitle = title ?? ""
        self.originalDetails = details ?? ""
        super.init(nibName: nil, bundle: nil)
        
        // Первичное заполнение полей
        titleTextField.text = title
        bodyTextView.text = details
        applyPlaceholdersIfNeeded()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        overrideUserInterfaceStyle = .dark
        view.backgroundColor = AppColor.background
        
        navigationItem.title = nil
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: barBackButton)
        
        titleTextField.addTarget(
            self,
            action: #selector(textEditingChanged),
            for: .editingChanged
        )
        
        updateSaveVisibility()
        setupLayout()
        bindInitialState()
        addKeyboardObservers()
        
        titleTextField.delegate = self
        bodyTextView.delegate = self
        titleTextField.becomeFirstResponder()
    }
    
    deinit { NotificationCenter.default.removeObserver(self) }
    
    // MARK: - IB Actions
    /// Закрыть редактор
    @objc private func closeTapped() { dismissOrPop() }
    
    /// Сохранить изменения
    @objc private func saveTapped() {
        let titleValue = titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let detailsValue = bodyTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !titleValue.isEmpty else { titleTextField.becomeFirstResponder(); return }
        
        onSave?(titleValue, (detailsValue?.isEmpty == true) ? nil : detailsValue)
        dismissOrPop()
    }
    
    /// Изменение текста в поле заголовка
    @objc private func textEditingChanged() { updateSaveVisibility() }
    
    // MARK: - Private Methods
    /// Разметка интерфейса
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
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor)
        ])
        
        // Заголовок + Дата
        let headerStack = UIStackView()
        headerStack.axis = .vertical
        headerStack.spacing = 4
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerStack.addArrangedSubview(titleTextField)
        headerStack.addArrangedSubview(dateLabel)
        contentStack.addArrangedSubview(headerStack)
        
        // Задача
        contentStack.addArrangedSubview(bodyTextView)
        bodyTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 240).isActive = true
        
        // Нижний спейсер
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        bottomSpacer.heightAnchor.constraint(equalToConstant: 0).isActive = true
        contentStack.addArrangedSubview(bottomSpacer)
    }
    
    /// Биндинг статического состояния
    private func bindInitialState() {
        dateLabel.text = dateText
    }
    
    /// Закрытие экрана: pop если есть стек, иначе dismiss
    private func dismissOrPop() {
        if let navigationControllerRef = navigationController,
           navigationControllerRef.viewControllers.first != self {
            navigationControllerRef.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    /// Текст описания без плейсхолдера
    private func normalizedDetails() -> String {
        (bodyTextView.text == bodyPlaceholder) ? "" : (bodyTextView.text ?? "")
    }
    
    /// Видимость «Сохранить»
    private func updateSaveVisibility() {
        let currentTitle = titleTextField.text?.trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""
        let currentDetails = normalizedDetails()
        
        switch mode {
        case .create:
            navigationItem.rightBarButtonItem = saveButtonItem
            saveButtonItem.isEnabled = !currentTitle.isEmpty
        case .edit:
            let changed = (currentTitle != originalTitle) || (currentDetails != originalDetails)
            navigationItem.rightBarButtonItem = changed ? saveButtonItem : nil
            saveButtonItem.isEnabled = !currentTitle.isEmpty
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
    
    // MARK: Keyboard
    private func addKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardFrameChange),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }
    
    /// Обработчик сдвига контента под клавиатуру
    @objc private func handleKeyboardFrameChange(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }
        
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

// MARK: - UITextViewDelegate
extension TaskEditorViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) { updateSaveVisibility() }
    
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
}

// MARK: - UITextFieldDelegate
extension TaskEditorViewController: UITextFieldDelegate {}
