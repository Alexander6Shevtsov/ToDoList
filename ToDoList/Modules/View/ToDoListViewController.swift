//
//  ToDoListViewController.swift
//  ToDoList
//

import UIKit

final class ToDoListViewController: UIViewController {
    var output: ToDoListViewOutput!
    
    // MARK: - State
    private var items: [ToDoViewModel] = []
    
    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let refreshControl = UIRefreshControl()
    private let searchController = UISearchController(searchResultsController: nil)
    
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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Задачи"
        view.backgroundColor = AppColor.black
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
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
        
        let searchTextField = searchController.searchBar.searchTextField
        searchTextField.textColor = AppColor.white
        searchTextField.tintColor = AppColor.yellow
        searchTextField.backgroundColor = AppColor.gray
        searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Поиск",
            attributes: [.foregroundColor: UIColor.secondaryLabel]
        )
        
        output.viewDidLoad()
    }
    
    // MARK: - Bottom bar
    private func setupBottomBar() {
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.backgroundColor = AppColor.gray
        view.addSubview(bottomBar)
        
        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 49)
        ])
        
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
        
        // Добавляем label
        counterLabel.translatesAutoresizingMaskIntoConstraints = false
        counterLabel.textColor = AppColor.white
        counterLabel.textAlignment = .center
        counterLabel.font = .systemFont(ofSize: 17, weight: .regular)
        bottomBar.addSubview(counterLabel)
        
        addButtonView.translatesAutoresizingMaskIntoConstraints = false
        addButtonView.tintColor = AppColor.yellow
        addButtonView.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
        addButtonView.backgroundColor = .clear
        addButtonView.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)
        bottomBar.addSubview(addButtonView)
        
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
}

// MARK: - View Input
extension ToDoListViewController: ToDoListViewInput {
    func display(items: [ToDoViewModel]) {
        DispatchQueue.main.async {
            self.items = items
            self.tableView.reloadData()
            self.counterLabel.text = "\(items.count) Задач"
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
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}

// MARK: - Table
extension ToDoListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int { items.count }
    
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
        cell.selectionStyle = .none
        cell.tintColor = AppColor.yellow
        cell.backgroundColor = AppColor.black
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let todoId = items[indexPath.row].id
        output.didSelectItem(id: todoId)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Swipe Done/Undo
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = items[indexPath.row]
        let todoId = item.id
        let actionTitle = item.isDone ? "Undo" : "Done"
        
        let toggle = UIContextualAction(style: .normal, title: actionTitle) { [weak self] _, _, finish in
            self?.output.didToggleDone(id: todoId)
            finish(true)
        }
        let config = UISwipeActionsConfiguration(actions: [toggle])
        config.performsFirstActionWithFullSwipe = true
        return config
    }
    
    // Swipe Delete
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let todoId = items[indexPath.row].id
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, finish in
            self?.output.didDelete(id: todoId)
            finish(true)
        }
        let config = UISwipeActionsConfiguration(actions: [delete])
        config.performsFirstActionWithFullSwipe = true
        return config
    }
}

// MARK: - Search
extension ToDoListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        output.didSearch(query: searchController.searchBar.text ?? "")
    }
}
