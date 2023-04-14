import SwiftUI
import FirebaseFirestoreSwift

struct User: Identifiable, Codable{
    @DocumentID var id: String?
    var username: String
    var userid: String
    var email: String
    var profileURL: URL
    var postsURL: [URL]
    
    enum CodingKeys: CodingKey{
        case id
        case username
        case userid
        case email
        case profileURL
        case postsURL
    }
}
