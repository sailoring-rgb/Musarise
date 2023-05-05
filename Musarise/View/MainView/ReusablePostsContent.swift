import SwiftUI
import FirebaseFirestore

struct ReusablePostsContent: View {
    
    @Binding var posts: [Post]
    @State var isFetching: Bool = true
    @State private var paginationDoc : QueryDocumentSnapshot?
    @AppStorage("user_UID") var userUID: String = ""
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false){
            LazyVStack{
                if isFetching{
                    ProgressView()
                        .padding(.top, 30)
                } else {
                    if posts.isEmpty{
                        Text("No posts were found..")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 30)
                    } else {
                        Posts()
                    }
                }
            }
            .padding(15)
        }
        .refreshable {
            isFetching = true
            posts = []
            await fetchPosts()
        }
        .task {
            guard posts.isEmpty else {return}
            await fetchPosts()
        }
    }
    
    @ViewBuilder
    func Posts() -> some View {
        ForEach(posts) { post in
            PostCardView(post: post) { updatedPost in
                if let index = posts.firstIndex(where: { post in post.id == updatedPost.id }) {
                    posts[index].likedIDs = updatedPost.likedIDs
                }
            } onDelete: {
                withAnimation(.easeInOut(duration: 0.25)){
                    posts.removeAll { post.id == $0.id }
                }
            }
            
            .onAppear{
                if post.id == posts.last?.id && paginationDoc != nil{
                    Task{await fetchPosts() }
                }
            }
            
            Divider()
                .padding(.top, 10)
                .padding(.bottom, 20)
        }
    }

    func fetchPosts() async{
        do {
            let userReference = Firestore.firestore().collection("Users")
            let query0 = userReference.whereField("userid", isEqualTo: userUID)
            let snapshot = try await query0.getDocuments()

            var following = snapshot.documents.first?.data()["following"] as? [String] ?? []

            following += [userUID] // Adiciona o novo elemento ao array
            print(following)

            var query: Query!
            if let paginationDoc {
                query = Firestore.firestore().collection("Posts")
                    .whereField("userid", in:following)
                    .order(by: "publishedDate", descending: true)
                    .start(afterDocument: paginationDoc)
                    .limit(to: 10)
            } else {
                query = Firestore.firestore().collection("Posts")
                    .whereField("userid", in:following)
                    .order(by: "publishedDate", descending: true)
                    .limit(to: 10)
            }
            
            let docs = try await query.getDocuments()
            let fetchedPosts = docs.documents.compactMap{ doc -> Post? in
                try? doc.data(as: Post.self)
            }
            
            await MainActor.run {
                posts.append(contentsOf: fetchedPosts)
                paginationDoc = docs.documents.last
                isFetching = false
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func getUserFromUsername(username: String) async throws -> User? {
        let userReference = Firestore.firestore().collection("Users")
        let query = userReference.whereField("username", isEqualTo: username)
        let snapshot = try await query.getDocuments()

        guard let userSnapshot = snapshot.documents.first else { return nil }
        let user = try userSnapshot.data(as: User.self)
        return user
    }

}

struct ReusablePostsView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
