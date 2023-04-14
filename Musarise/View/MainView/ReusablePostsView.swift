import SwiftUI
import FirebaseFirestore

struct ReusablePostsView: View {
    @Binding var posts: [Post]
    @State var isFetching: Bool = true
    
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
    func Posts()->some View {
        ForEach(posts){ post in
            PostCardView(post: post){ updatedPost in
                if let index = posts.firstIndex(where: {
                    post in post.id == updatedPost.id
                }){
                    posts[index].likedIDs = updatedPost.likedIDs
                }
            } onDelete: {
                withAnimation(.easeInOut(duration: 0.25)){
                    posts.removeAll{post == $0}
                }
            }
            
            Divider()
                .padding(.horizontal,5)
        }
    }
    
    func fetchPosts() async{
        do {
            var query: Query!
            query = Firestore.firestore().collection("Posts")
                .order(by: "publishedDate", descending: true)
                .limit(to: 15)
            let docs = try await query.getDocuments()
            let fetchedPosts = docs.documents.compactMap{ doc -> Post? in
                try? doc.data(as: Post.self)
            }
            await MainActor.run(body: {
                posts = fetchedPosts
                isFetching = false
            })
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct ReusablePostsView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
