//
//  SearchViewController.swift
//  Pokemon
//
//  Created by 강호성 on 2/15/24.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxDataSources
import ReactorKit

final class SearchViewController: BaseViewController, ReactorKit.View {
    // MARK: - Properties
    private let tableView = UITableView()
    private let searchController = UISearchController(searchResultsController: nil)
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        return indicator.then {
            $0.color = .black
            $0.hidesWhenStopped = true
        }
    }()
    private lazy var scrollToTopButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "arrow.up"), for: .normal)
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 25
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.3
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 4
    }

    // MARK: - Initialization
    required init(reactor: SearchReactor) {
        super.init()
        self.reactor = reactor
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setView()
        setConstraints()
        setConfiguration()
    }

    // MARK: - Binding
    func bind(reactor: SearchReactor) {
        // Action
        searchController.searchBar.rx.text.orEmpty
            .distinctUntilChanged()
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { Reactor.Action.updateSearchQuery($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        searchController.searchBar.rx.searchButtonClicked
            .withLatestFrom(searchController.searchBar.rx.text.orEmpty)
            .filter { !$0.isEmpty }
            .map { Reactor.Action.search($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        tableView.rx.contentOffset
            .filter { [weak self] offset in
                guard let self = self else { return false }
                return offset.y + self.tableView.frame.height >= self.tableView.contentSize.height - 100
            }
            .map { _ in Reactor.Action.loadNextPage }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // State
        reactor.state.map { $0.isLoading }
            .distinctUntilChanged()
            .bind(to: loadingIndicator.rx.isAnimating)
            .disposed(by: disposeBag)

        reactor.state.map { !$0.isLoading }
            .distinctUntilChanged()
            .bind(to: loadingIndicator.rx.isHidden)
            .disposed(by: disposeBag)

        reactor.state.map { $0.searchResult }
            .bind(to: tableView.rx.items(cellIdentifier: PokemonCardTableViewCell.reuseIdentifier, cellType: PokemonCardTableViewCell.self)) { _, item, cell in
                cell.configure(with: item)
            }
            .disposed(by: disposeBag)

        reactor.state.map { $0.noResults }
            .distinctUntilChanged()
            .bind(onNext: { [weak self] noResults in
                if noResults {
                    self?.searchController.searchBar.resignFirstResponder()
                    self?.showNoResultsAlert()
                }
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Helpers
    override func setView() {
        super.setView()

        searchController.searchBar.placeholder = " 포켓몬을 검색하세요!"
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController

        tableView.delegate = nil
        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
        view.addSubview(scrollToTopButton)

    }

    override func setConstraints() {
        super.setConstraints()
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        scrollToTopButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
            $0.width.height.equalTo(50)
        }
    }

    override func setConfiguration() {
        super.setConfiguration()
        tableView.register(PokemonCardTableViewCell.self, forCellReuseIdentifier: PokemonCardTableViewCell.reuseIdentifier)
        tableView.rx.setDelegate(self).disposed(by: disposeBag)

        searchController.searchBar.autocorrectionType = .no
        searchController.searchBar.spellCheckingType = .no
    }

    private func showNoResultsAlert() {
        let alertController = UIAlertController(title: "검색 결과 없음", message: "입력한 검색어에 해당하는 포켓몬이 없습니다.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    private func showErrorAlert(message: String) {
        let alertController = UIAlertController(title: "에러", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180
    }
}
