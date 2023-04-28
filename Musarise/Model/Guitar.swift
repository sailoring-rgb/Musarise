//
//  Guitar.swift
//  Musarise
//
//  Created by parola on 28/04/2023.
//

import SwiftUI
import FirebaseFirestoreSwift

struct Guitar: Identifiable, Hashable, Codable{
    @DocumentID var id: String?
    var soundURL: URL
    var name: String

    enum CodingKeys: CodingKey{
        case id
        case soundURL
        case name
    }
}
