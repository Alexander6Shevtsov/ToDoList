//
//  ToDoListViewController.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 31.08.2025.
//

import UIKit

final class ToDoListViewController: UIViewController {
    var output: ToDoListViewOutput!
    
    private var items: [ToDoViewModel] = []
    private let refreshControl = UIRefreshControl()
    
    // UI
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let activity = UIActivityIndicatorView(style: .medium)
    private let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ToDos"
        view.backgroundColor = .systemBackground
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(Cell.self, forCellReuseIdentifier: Cell.reuseId)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        // Search
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        activity.hidesWhenStopped = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activity)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTapped)
        )
        
        output.viewDidLoad()
    }
    
    @objc private func didPullToRefresh() {
        output.didSearch(query: "")
        output.viewDidLoad()
    }
    
    @objc private func addTapped() {
        output.didTapAdd()
    }
}

// MARK: - ViewInput
extension ToDoListViewController: ToDoListViewInput {
    func display(items: [ToDoViewModel]) {
        self.items = items
        tableView.reloadData()
    }
    
    func setLoading(_ isLoading: Bool) {
        isLoading ? activity.startAnimating() : activity.stopAnimating()
        if !isLoading { refreshControl.endRefreshing() }
    }
    
    func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Table DS/Delegate
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
            withIdentifier: Cell.reuseId,
            for: indexPath
        ) as! Cell
        cell.configure(with: viewModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        output.didSelectItem(id: items[indexPath.row].id)
    }
    
    // Свайпы
    func tableView(
        _ tableView: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let viewModel = items[indexPath.row]
        let done = UIContextualAction(
            style: .normal,
            title: viewModel.isDone ? "Undone" : "Done"
        ) { [weak self] _,_, finish in
            self?.output.didToggleDone(id: viewModel.id); finish(true)
        }
        return UISwipeActionsConfiguration(actions: [done])
    }
    
    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let viewModel = items[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _,_, finish in
            self?.output.didDelete(id: viewModel.id); finish(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

// MARK: - Search
extension ToDoListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        output.didSearch(query: searchController.searchBar.text ?? "")
    }
}

// MARK: - Ячейка
private final class Cell: UITableViewCell {
    static let reuseId = "Cell"
    
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let metaLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        
        let contentStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, metaLabel])
        contentStackView.axis = .vertical
        contentStackView.spacing = 2
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(contentStackView)
        
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel
        metaLabel.font = .preferredFont(forTextStyle: .caption1)
        metaLabel.textColor = .tertiaryLabel
        metaLabel.numberOfLines = 1
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func configure(with viewModel: ToDoViewModel) {
        titleLabel.text = viewModel.title
        subtitleLabel.isHidden = (viewModel.subtitle ?? "").isEmpty
        subtitleLabel.text = viewModel.subtitle
        metaLabel.text = viewModel.meta
        accessoryType = viewModel.isDone ? .checkmark : .disclosureIndicator
    }
}
