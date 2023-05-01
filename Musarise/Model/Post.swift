import SwiftUI
import FirebaseFirestoreSwift

struct Post: Identifiable, Codable, Equatable, Hashable {
    
    @DocumentID var id: String?
    var text: String
    var imageURL: URL?
    var imageReferenceID: String = ""
    var publishedDate: Date = Date()
    var likedIDs: [String] = []
    var userName: String
    var userid: String
    var iconURL: URL
    
    enum CodingKeys: CodingKey{
        case id
        case text
        case imageURL
        case imageReferenceID
        case publishedDate
        case likedIDs
        case userName
        case userid
        case iconURL
    }
}
