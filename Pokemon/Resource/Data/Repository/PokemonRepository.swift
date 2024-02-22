
//
//  SearchRepositoryExtension+.swift
//  Pokemon
//
//  Created by 김기현 on 2/12/24.
//

import Foundation
import Moya

final class PokemonRepository: PokemonRepositoryType {
    private let provider: MoyaProvider<PokemonTarget>
    init() { provider = MoyaProvider<PokemonTarget>() }
}

extension PokemonRepository {
    func fetchCards(
        request: CardsRequest,
        completion: @escaping (Result<[PokemonCard], Error>) -> Void
    ) {
        provider.request(.fetchCards(parameters: request.toDictionary)) { result in
            switch result {
            case .success(let response):
                do {
                    let apiResponse = try response.map(APIResponse.self)
                    completion(.success(apiResponse.data))

                } catch {
                    completion(.failure(error))
                }

            case .failure(let error):
                print("API 호출 에러: \(error)")
                completion(.failure(error))
            }
        }
    }
}
