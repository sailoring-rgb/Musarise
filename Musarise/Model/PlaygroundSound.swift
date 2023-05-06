import SwiftUI
import FirebaseFirestoreSwift

struct PlaygroundSound: Identifiable, Codable{
    
    @DocumentID var id: String?
    var publishedDate: Date = Date()
    var soundURL: URL
    var instrumentName: String
    var instrumentIcon: String
    var userid: String

    enum CodingKeys: CodingKey{
        case id
        case publishedDate
        case soundURL
        case instrumentName
        case instrumentIcon
        case userid
    }
}
