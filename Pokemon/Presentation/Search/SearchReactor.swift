import ReactorKit
import RxSwift
import RealmSwift
import Realm

class SearchReactor: Reactor {
    enum Action {
        case updateSearchQuery(String)
        case search(String)
        case loadNextPage
        case scrollTop
        case updateFavoriteStatus(String, Bool)

    }
    enum Mutation {
        case setQuery(String)
        case setSearchResults([PokemonCard])
        case appendSearchResults([PokemonCard])
        case setLoading(Bool)
        case setCanLoadMore(Bool)
        case setNoResults(Bool)
        case setScrollTop(Bool)
        case setFavorite(String, Bool)

    }
    struct State {
        var query: String = ""
        var searchResult: [PokemonCard] = []
        var isLoading: Bool = false
        var canLoadMore: Bool = true
        var noResults: Bool = false
        var scrollTop: Bool = false
        var favorites: [String] = []

    }
    var initialState = State()
    private let pokemonRepository: PokemonRepositoryType
    private var realm: Realm

    // MARK: - Initialization
    init(pokemonRepository: PokemonRepositoryType) {
        self.pokemonRepository = pokemonRepository
        do {
            self.realm = try Realm()
        } catch {
            fatalError("Realm 초기화 실패: \(error)")
        }
        self.initialState = State()
    }
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .updateSearchQuery(let query):
            return .concat([
                .just(.setQuery(query)),
                .just(.setNoResults(false))
            ])

        case .search(let query):
            guard !query.isEmpty else {
                return .concat([
                    .just(.setLoading(false)),
                    .just(.setSearchResults([])),
                    .just(.setNoResults(true))
                ])
            }

            let initialPage = 1
            return .concat([
                .just(.setLoading(true)),
                searchQuery(query: query, page: initialPage)
                    .map { results in
                        if results.isEmpty {
                            return .setNoResults(true)
                        } else {
                            return .setSearchResults(results)
                        }
                    },
                .just(.setLoading(false))
            ])
        case .loadNextPage:
            guard !currentState.isLoading, currentState.canLoadMore else {
                return .empty()
            }

            let nextPage = (currentState.searchResult.count / 20) + 1

            return .concat([
                .just(.setLoading(true)),
                searchQuery(query: currentState.query, page: nextPage)
                    .map { .appendSearchResults($0) },
                .just(.setLoading(false)),
                .just(.setCanLoadMore(true))
            ])
        case .scrollTop:
            return .concat([
                .just(.setScrollTop(true)),
                .just(.setScrollTop(false))
            ])
        case .updateFavoriteStatus(let cardID, let isFavorite):
            return Observable.create { [weak self] observer in
                   guard let self = self else {
                       observer.onCompleted()
                       return Disposables.create()
                   }
                   do {
                       let realm = try Realm()
                       if let cardToUpdate = realm.object(ofType: RealmPokemonCard.self, forPrimaryKey: cardID) {
                           try realm.write {
                               cardToUpdate.isFavorite = isFavorite
                               realm.add(cardToUpdate, update: .modified)
                           }
                           observer.onNext(Mutation.setFavorite(cardID, isFavorite))
                           observer.onCompleted()
                       } else {
                           observer.onError(NSError(domain: "com.example.Pokemon", code: 0, userInfo: [NSLocalizedDescriptionKey: "Card not found"]))
                       }
                   } catch {
                       observer.onError(error)
                   }
                   return Disposables.create()
               }

        }
    }
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setQuery(let query):
            newState.query = query

        case .setSearchResults(let result):
            newState.searchResult = result
            newState.canLoadMore = true

        case .appendSearchResults(let results):
            newState.searchResult += results

        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setCanLoadMore(let canLoadMore):
            newState.canLoadMore = canLoadMore
        case .setNoResults(let noResults):
            newState.noResults = noResults

        case .setScrollTop(let scrollToTop):
            newState.scrollTop = scrollToTop

        case .setFavorite(let cardID, let isFavorite):
            if isFavorite {
                newState.favorites.append(cardID)
            } else {
                if let index = newState.favorites.firstIndex(of: cardID) {
                    newState.favorites.remove(at: index)
                }
            }
        }

        return newState
    }

    private func searchQuery(query: String, page: Int) -> Observable<[PokemonCard]> {
        let pageSize = 20
        let request = CardsRequest(query: query, page: page, pageSize: pageSize)

        return Observable.create { observer in
            self.pokemonRepository.fetchCards(request: request) { result in
                switch result {
                case .success(let response):
                    observer.onNext(response.data)
                case .failure:
                    observer.onNext([])
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    private func updateFavorites(_ favorites: [String], cardID: String, isFavorite: Bool) -> [String] {
        var updatedFavorites = favorites

        if isFavorite {
            if !updatedFavorites.contains(cardID) {
                updatedFavorites.append(cardID)
            }
        } else {
            updatedFavorites.removeAll { $0 == cardID }
        }

        return updatedFavorites
    }
}

