import SwiftUI
import FirebaseFirestoreSwift

struct Rotation: Identifiable, Hashable, Codable{
    @DocumentID var id: String?
    var x: Double
    var y: Double
    var z: Double
    var tapped: Bool

    enum CodingKeys: CodingKey{
        case id
        case x
        case y
        case z
        case tapped
    }
}

struct TrainingData: Identifiable, Hashable, Codable{
    @DocumentID var id: String?
    var rotationList: [Rotation]

    enum CodingKeys: CodingKey{
        case id
        case rotationList
    }
}
