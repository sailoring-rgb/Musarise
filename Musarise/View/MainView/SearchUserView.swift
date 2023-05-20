import SwiftUI
import Firebase
import FirebaseFirestore
import SDWebImageSwiftUI

struct SearchUserView: View {
    @State private var fetchedUsers: [User] = []
    @State private var searchText: String = ""
    @Environment(\.dismiss) private var dismiss
    @State private var posts: [Post] = []
    
    var body: some View {
        List{
            ForEach(fetchedUsers) { user in
                NavigationLink(destination: OtherProfileView(username: user.username)) {
                    HStack{
                        WebImage(url: user.iconURL)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 35, height: 35)
                            .clipShape(Circle())
                        
                        Text(user.username)
                            .font(.callout)
                            .hAlign(.leading)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Search User" )
        .searchable(text: $searchText)
        .onSubmit(of: .search, {
            Task{await searchUsers()}
        })
        .onChange(of: searchText, perform: { newValue in
            if newValue.isEmpty{
                fetchedUsers = []
            }
        })
    }
        
    func searchUsers() async {
        do {
            let searchTextLowercased = searchText.lowercased()
            
            let query = try await Firestore.firestore().collection("Users").whereField("username", isEqualTo: searchTextLowercased).getDocuments()
            
            var users = query.documents.compactMap { doc -> User? in
                try? doc.data(as: User.self)
            }
            
            if users.isEmpty {
                let startWithQuery = try await Firestore.firestore().collection("Users").whereField("username", isGreaterThanOrEqualTo: searchTextLowercased).getDocuments()
                
                for userDocument in startWithQuery.documents {
                    if let user = try? userDocument.data(as: User.self), user.username.lowercased().hasPrefix(searchTextLowercased) {
                        users.append(user)
                    }
                }
            }
            
            let usersFiltered = users
            
            await MainActor.run {
                fetchedUsers = usersFiltered
            }
        } catch {
            print(error.localizedDescription)
        }
    }


}

struct SearchUserView_Previews: PreviewProvider {
    static var previews: some View {
        SearchUserView()
    }
}
