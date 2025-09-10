//
//  ToDoListViewController.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 01.09.2025.
//

import UIKit

final class ToDoListViewController: UIViewController {
    
    // MARK: - Public Properties
    var output: ToDoListViewOutput!
    
    // MARK: - Private Properties
    private var items: [ToDoViewModel] = []
    
    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let refreshControl = UIRefreshControl()
    private let searchController = UISearchController(searchResultsController: nil)
    private let bottomBarBackground = UIView()
    private let bottomBar = UIView()
    private let counterLabel = UILabel()
    private let addButtonView = UIButton(type: .system)
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "Нет задач"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Задачи"
        view.backgroundColor = AppColor.background
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.backButtonDisplayMode = .generic
        navigationItem.backButtonTitle = "Назад"
        
        setupBottomBar()
        
        // Table
        tableView.backgroundColor = AppColor.black
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 88
        tableView.register(ToDoCell.self, forCellReuseIdentifier: ToDoCell.reuseId)
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor)
        ])
        
        // Empty state
        view.addSubview(emptyStateLabel)
        NSLayoutConstraint.activate([
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
        emptyStateLabel.isHidden = true
        
        // Pull-to-refresh
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        
        // Search
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        
        let searchBar = searchController.searchBar
        let searchTextField  = searchBar.searchTextField
        
        searchTextField.backgroundColor = UIColor(white: 1.0, alpha: 0.16)
        searchTextField.textColor = AppColor.white
        searchTextField.tintColor = AppColor.yellow
        searchTextField.layer.cornerRadius = 16
        searchTextField.layer.masksToBounds = true
        
        searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Search",
            attributes: [
                .foregroundColor: UIColor(white: 1.0, alpha: 0.78),
                .font: UIFont.systemFont(ofSize: 17, weight: .regular)
            ]
        )
        
        // Иконки поиска
        let symbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: 17,
            weight: .semibold
        )
        let searchIconImage = UIImage(
            systemName: "magnifyingglass"
        )?
            .applyingSymbolConfiguration(symbolConfiguration)?
            .withTintColor(
                UIColor(
                    white: 1.0,
                    alpha: 0.78
                ),
                renderingMode: .alwaysOriginal
            )
        searchBar.setImage(searchIconImage, for: .search, state: .normal)
        
        let micImg = UIImage(systemName: "mic.fill")?
            .applyingSymbolConfiguration(symbolConfiguration)?
            .withTintColor(
                UIColor(white: 1.0, alpha: 0.78),
                renderingMode: .alwaysOriginal
            )
        searchBar.setImage(micImg, for: .bookmark, state: .normal)
        searchBar.showsBookmarkButton = true
        searchBar.delegate = self
        
        output.viewDidLoad()
    }
    
    // MARK: - Bottom bar
    private func setupBottomBar() {
        bottomBarBackground.translatesAutoresizingMaskIntoConstraints = false
        bottomBarBackground.backgroundColor = AppColor.gray
        view.addSubview(bottomBarBackground)
        
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.backgroundColor = AppColor.gray
        view.addSubview(bottomBar)
        
        NSLayoutConstraint.activate([
            // фон
            bottomBarBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBarBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBarBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // панель
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 49),
            bottomBarBackground.topAnchor.constraint(equalTo: bottomBar.topAnchor)
        ])
        
        // Верхняя линия
        let topLine = UIView()
        topLine.backgroundColor = AppColor.stroke
        topLine.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(topLine)
        NSLayoutConstraint.activate([
            topLine.topAnchor.constraint(equalTo: bottomBar.topAnchor),
            topLine.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            topLine.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            topLine.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        // Счётчик
        counterLabel.translatesAutoresizingMaskIntoConstraints = false
        counterLabel.textColor = AppColor.white
        counterLabel.textAlignment = .center
        counterLabel.font = .systemFont(ofSize: 17, weight: .regular)
        bottomBar.addSubview(counterLabel)
        
        // Кнопка добавления
        addButtonView.translatesAutoresizingMaskIntoConstraints = false
        addButtonView.tintColor = AppColor.yellow
        addButtonView.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
        addButtonView.backgroundColor = .clear
        addButtonView.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)
        bottomBar.addSubview(addButtonView)
        
        // Индикатор
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        bottomBar.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            counterLabel.centerXAnchor.constraint(equalTo: bottomBar.centerXAnchor),
            counterLabel.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            
            addButtonView.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            addButtonView.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            addButtonView.widthAnchor.constraint(equalToConstant: 44),
            addButtonView.heightAnchor.constraint(equalToConstant: 44),
            
            activityIndicator.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            activityIndicator.trailingAnchor.constraint(equalTo: addButtonView.leadingAnchor, constant: -12)
        ])
    }
    
    private func updateEmptyState() {
        let isEmpty = items.isEmpty
        emptyStateLabel.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
    
    @objc private func didPullToRefresh() {
        searchController.isActive = false
        searchController.searchBar.text = ""
        output.viewDidLoad()
    }
    
    @objc private func didTapAdd() {
        output.didTapAdd()
    }
    
    @objc private func didTapMic() {
        let alert = UIAlertController(
            title: "Voice",
            message: "Голосовой поиск не реализован",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - View Input
extension ToDoListViewController: ToDoListViewInput {
    func display(items: [ToDoViewModel]) {
        DispatchQueue.main.async {
            self.items = items
            self.tableView.reloadData()
            self.updateEmptyState()
        }
    }
    
    func setLoading(_ isLoading: Bool) {
        DispatchQueue.main.async {
            if isLoading {
                self.activityIndicator.startAnimating()
                self.addButtonView.isEnabled = false
                self.addButtonView.alpha = 0.5
            } else {
                self.activityIndicator.stopAnimating()
                self.addButtonView.isEnabled = true
                self.addButtonView.alpha = 1.0
            }
            self.refreshControl.endRefreshing()
        }
    }
    
    func showError(_ message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Error",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    func setCounterText(_ text: String) { counterLabel.text = text }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension ToDoListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let viewModel = items[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ToDoCell.reuseId,
            for: indexPath
        ) as! ToDoCell
        
        cell.configure(
            title: viewModel.title,
            body: viewModel.subtitle,
            date: viewModel.meta,
            isDone: viewModel.isDone
        )
        
        cell.onToggleTapped = { [weak self] in
            self?.output.didToggleDone(id: viewModel.id)
        }
        
        cell.selectionStyle = .none
        cell.tintColor = AppColor.yellow
        cell.backgroundColor = AppColor.black
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let todoIdentifier = items[indexPath.row].id
        output.didSelectItem(id: todoIdentifier)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Search
extension ToDoListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        output.didSearch(query: searchController.searchBar.text ?? "")
    }
}

// MARK: - UISearchBarDelegate
extension ToDoListViewController: UISearchBarDelegate {
    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
        didTapMic()
    }
}
