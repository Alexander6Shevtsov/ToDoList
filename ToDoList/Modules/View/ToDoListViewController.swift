//
//  ToDoListViewController.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 31.08.2025.
//

import UIKit

final class ToDoListViewController: UIViewController {
    var output: ToDoListViewOutput!
    
    // State
    private var items: [ToDoViewModel] = []
    
    // UI
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private var addButton: UIBarButtonItem?
    private let cellReuseId = "todoCell"
    private let searchController = UISearchController(searchResultsController: nil)
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "Нет задач"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ToDos"
        view.backgroundColor = AppColor.black
        
        // Table
        tableView.backgroundColor = AppColor.black
        tableView.separatorColor = AppColor.stroke
        tableView.separatorInsetReference = .fromCellEdges
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseId)
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
        searchController.searchBar.overrideUserInterfaceStyle = .dark
        searchController.obscuresBackgroundDuringPresentation = false
        definesPresentationContext = true
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        let searchTextField = searchController.searchBar.searchTextField
        searchTextField.textColor = AppColor.white
        searchTextField.tintColor = AppColor.yellow
        searchTextField.backgroundColor = AppColor.gray
        searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Search",
            attributes: [.foregroundColor: UIColor.secondaryLabel]
        )
        
        // Add button / loader
        let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))
        addBarButton.tintColor = AppColor.yellow
        navigationItem.rightBarButtonItem = addBarButton
        addButton = addBarButton
        activityIndicator.hidesWhenStopped = true
        
        output.viewDidLoad()
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

// MARK: - ToDoListViewInput
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
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.activityIndicator)
            } else {
                self.activityIndicator.stopAnimating()
                self.navigationItem.rightBarButtonItem = self.addButton
            }
            self.refreshControl.endRefreshing()
        }
    }
    
    func didChangeLoading(_ isLoading: Bool) {
        setLoading(isLoading)
    }
    
    func showError(_ message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    func didFail(error: Error) {
        showError(error.localizedDescription)
    }
}

// MARK: - UITableViewDataSource / UITableViewDelegate
extension ToDoListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId)
        ?? UITableViewCell(style: .subtitle, reuseIdentifier: cellReuseId)
        
        var content = cell.defaultContentConfiguration()
        content.textProperties.color = AppColor.white
        content.textProperties.numberOfLines = 1
        content.secondaryTextProperties.color = UIColor(white: 1, alpha: 0.7)
        content.secondaryTextProperties.numberOfLines = 2

        content.text = viewModel.title
        content.secondaryText = viewModel.subtitle ?? viewModel.meta
        cell.contentConfiguration = content
        
        cell.accessoryType = (viewModel.subtitle?.isEmpty == false) ? .disclosureIndicator : .none
        cell.selectionStyle = .none
        cell.tintColor = AppColor.yellow
        cell.backgroundColor = .clear
        cell.backgroundColor = AppColor.black

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let todoId = items[indexPath.row].id
        output.didSelectItem(id: todoId)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Swipe Done/Undo
    func tableView(_ tableView: UITableView,
                   leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
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
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
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

// MARK: - UISearchResultsUpdating
extension ToDoListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        output.didSearch(query: searchController.searchBar.text ?? "")
    }
}
