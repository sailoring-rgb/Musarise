import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore

struct FollowersListView: View {

    @State var users: [String]
    @Binding var isFollowing: Bool
    
    var body: some View {
        Color.clear
        NavigationView{
            ScrollView(.vertical, showsIndicators: false){
                VStack(alignment: .leading, spacing: 15){
                    if users.isEmpty{
                        if !isFollowing{
                            Text("No follower were found..")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 30)
                        } else {
                            Text("No following were found..")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 30)
                        }
                    } else {
                        ForEach(users, id: \.self) { userid in
                            FollowerCard(userid: userid)
                        }
                    }
                }
                .padding(20)
            }
            .navigationBarTitle(isFollowing ? "Following" : "Followers")
            .navigationBarTitleDisplayMode(.inline)
        }
        .frame(width: UIScreen.main.bounds.size.width / 1.5, height: UIScreen.main.bounds.size.height / 3)
        .padding(.bottom, 10)
        .background(Color.white)
        .cornerRadius(20)
    }
}

struct FollowerCard: View {
    
    @State var userid: String
    @State private var username: String?
    @State private var iconURL: String?
    
    var body: some View{
        ScrollView{
            if let username = self.username, let iconURL = self.iconURL{
                NavigationLink(destination: OtherProfileView(username: username)){
                    HStack{
                        WebImage(url: URL(string: iconURL))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 35, height: 35)
                            .clipShape(Circle())
                        
                        Text(username)
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .task {
            self.username = try? await getUsername()
            self.iconURL = try? await getIconURL()
        }
        .vAlign(.leading)
    }
    
    func getUsername() async throws -> String? {
        let userReference = Firestore.firestore().collection("Users")
        let query = userReference.whereField("userid", isEqualTo: userid)
        let snapshot = try await query.getDocuments()

        guard let username = snapshot.documents.first?.data()["username"] as? String else { return nil }
        
        return username
    }
    
    func getIconURL() async throws -> String? {
        let userReference = Firestore.firestore().collection("Users")
        let query = userReference.whereField("userid", isEqualTo: userid)
        let snapshot = try await query.getDocuments()

        guard let iconURL = snapshot.documents.first?.data()["iconURL"] as? String else { return nil }
        
        return iconURL
    }
}

struct Previews_FollowersListView_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
