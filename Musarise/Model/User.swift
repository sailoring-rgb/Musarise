import SwiftUI
import FirebaseFirestoreSwift

struct User: Identifiable, Codable{
    @DocumentID var id: String?
    var username: String
    var userid: String
    var email: String
    var iconURL: URL
    var following: [String]
    var followers: [String]

    enum CodingKeys: CodingKey{
        case id
        case username
        case userid
        case email
        case iconURL
        case following
        case followers
    }
}
