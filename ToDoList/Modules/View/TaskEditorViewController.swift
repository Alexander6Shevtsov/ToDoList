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
    
    // MARK: Init
    private let mode: TaskEditorMode
    private let dateText: String
    
    private lazy var barBackButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.setTitle(" Назад", for: .normal)
        b.tintColor = AppColor.yellow
        b.setTitleColor(AppColor.yellow, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return b
    }()
    
    init(mode: TaskEditorMode, title: String?, details: String?, dateText: String) {
        self.mode = mode
        self.dateText = dateText
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
        let f = UITextField()
        f.font = .systemFont(ofSize: 34, weight: .bold)
        f.textColor = AppColor.white
        f.tintColor = AppColor.yellow
        f.placeholder = "Название"
        f.translatesAutoresizingMaskIntoConstraints = false
        return f
    }()
    
    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.textColor = UIColor(white: 1, alpha: 0.6)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let bodyTextView: UITextView = {
        let v = UITextView()
        v.backgroundColor = .clear
        v.textColor = AppColor.white
        v.tintColor = AppColor.yellow
        v.font = .systemFont(ofSize: 20, weight: .regular)
        v.textContainerInset = .zero
        v.textContainer.lineFragmentPadding = 0
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let bottomSpacer = UIView() // чтобы клавиатура не перекрывала
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        view.backgroundColor = AppColor.black
        
        navigationItem.title = nil
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.leftBarButtonItem  = UIBarButtonItem(
            customView: barBackButton
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Сохранить",
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = AppColor.yellow
        
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

        // Шапка: Заголовок + Дата вплотную
        let headerStack = UIStackView()
        headerStack.axis = .vertical
        headerStack.spacing = 4 // ближе к заголовку, как в макете
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
        NotificationCenter.default.addObserver(self, selector: #selector(kb), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    @objc private func kb(_ n: Notification) {
        guard
            let userInfo = n.userInfo,
            let end = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
        else { return }
        let bottom = max(0, view.bounds.height - end.origin.y)
        UIView.animate(withDuration: duration) { [weak self] in
            self?.scrollView.contentInset.bottom = bottom
            self?.scrollView.verticalScrollIndicatorInsets.bottom = bottom
        }
    }
}
