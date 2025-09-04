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
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let activity = UIActivityIndicatorView(style: .medium)
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
        
        tableView.backgroundColor = AppColor.black
        tableView.separatorColor = AppColor.stroke
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(Cell.self, forCellReuseIdentifier: Cell.reuseId)
        tableView.keyboardDismissMode = .onDrag
        view.addSubview(tableView)
        
        view.addSubview(emptyStateLabel)
        NSLayoutConstraint.activate([
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
        emptyStateLabel.isHidden = true
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(
            self,
            action: #selector(
                didPullToRefresh
            ),
            for: .valueChanged
        )
        
        // Search
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.overrideUserInterfaceStyle = .dark
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        let stf = searchController.searchBar.searchTextField
        stf.textColor = AppColor.white
        stf.tintColor = AppColor.yellow
        stf.backgroundColor = AppColor.gray
        stf.attributedPlaceholder = NSAttributedString(
            string: "Search",
            attributes: [.foregroundColor: UIColor.secondaryLabel]
        )
        
        activity.hidesWhenStopped = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: activity)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(didTapAdd)
        )
        
        output.viewDidLoad()
    }
    
    private func updateEmptyState() {
        let isEmpty = items.isEmpty
        emptyStateLabel.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
    
    @objc private func didPullToRefresh() {
        searchController.searchBar.text = ""
        output.viewDidLoad()
    }
    
    // MARK: - Actions
    @objc private func didTapAdd() {
        output.didTapAdd()
    }
}

// MARK: - ViewInput
extension ToDoListViewController: ToDoListViewInput {
    func display(items: [ToDoViewModel]) {
        self.items = items
        tableView.reloadData()
        updateEmptyState()
    }
    
    func setLoading(_ isLoading: Bool) {
        isLoading ? activity.startAnimating() : activity.stopAnimating()
        if !isLoading { refreshControl.endRefreshing() }
    }
    
    func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
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
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Cell.reuseId,
            for: indexPath
        ) as! Cell
        cell.configure(with: items[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let id = items[indexPath.row].id
        output.didSelectItem(id: id)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Свайпы
    func tableView(
        _ tableView: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let item = items[indexPath.row]
        let id = item.id
        let actionTitle = item.isDone ? "Undo" : "Done"
        
        let toggle = UIContextualAction(style: .normal, title: actionTitle) { [weak self] _,_, done in
            self?.output.didToggleDone(id: id)
            done(true)
        }
        
        let configuration = UISwipeActionsConfiguration(actions: [toggle])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }
    
    
    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let id = items[indexPath.row].id
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _,_, done in
            self?.output.didDelete(id: id); done(true)
        }
        let cfg = UISwipeActionsConfiguration(actions: [delete])
        cfg.performsFirstActionWithFullSwipe = true
        return cfg
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
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        titleLabel.textColor = AppColor.white
        subtitleLabel.textColor = .secondaryLabel
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        preservesSuperviewLayoutMargins = false
    }
}
