import SwiftUI
import FirebaseFirestoreSwift

struct Challenge: Identifiable, Codable{
    
    @DocumentID var id: String?
    var publishedDate: Date = Date()
    var soundURL: URL
    var imageURL: URL
    var instrumentName: String
    var instrumentIcon: String
    var challengeTitle: String
    var challengeDescription: String

    enum CodingKeys: CodingKey{
        case id
        case publishedDate
        case soundURL
        case instrumentName
        case instrumentIcon
        case challengeTitle
        case challengeDescription
        case imageURL
    }
}
