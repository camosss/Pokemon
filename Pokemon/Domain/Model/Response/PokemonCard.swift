//
//  PokemonCard.swift
//  Pokemon
//
//  Created by 김기현 on 2/12/24.
//

import Foundation

struct APIResponse: Codable {
    let data: [PokemonCard]
}

struct PokemonCard: Codable {
    let id: String
    let name: String
    let hp: String?
    struct Images: Codable {
        let small: URL
        let large: URL
    }
    private let images: Images

    var imageUrlSmall: URL {
        return images.small
    }

    var imageUrlLarge: URL {
        return images.large
    }
}
