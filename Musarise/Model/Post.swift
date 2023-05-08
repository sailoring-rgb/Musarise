import SwiftUI
import FirebaseFirestoreSwift

struct Comment: Codable, Hashable{
    var userIconUrl: URL
    var userName: String
    var text: String
    var publishedDate: Date = Date()
    
    enum CodingKeys: CodingKey {
         case userIconUrl
         case userName
         case text
         case publishedDate
     }
}

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
    var soundURL: URL?
    var comments: [Comment]?
    
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
        case soundURL
        case comments
    }
}
