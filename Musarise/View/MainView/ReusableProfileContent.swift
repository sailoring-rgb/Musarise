import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore

struct ReusableProfileContent: View {
    var user: User
    @Binding var posts: [Post]
    @State var isFetching: Bool = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false){
            LazyVStack{
                HStack(spacing: 12){
                    WebImage(url: user.iconURL).placeholder{
                        Image("NullProfile")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 6){
                        Text(user.username)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .hAlign(.leading)
                }
                
                Text("My Posts")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .hAlign(.leading)
                    .padding(.vertical,15)
                
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
                        Posts2()
                    }
                }
            }
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
    func Posts2()->some View {
        ForEach(posts){ post in
            PostCardView(post: post){ updatedPost in
                if let index = posts.firstIndex(where: {
                    post in post.id == updatedPost.id
                }){
                    posts[index].likedIDs = updatedPost.likedIDs
                }
            } onDelete: {
                withAnimation(.easeInOut(duration: 0.25)){
                    posts.removeAll{post.id == $0.id}
                }
            }
            
            Divider()
                .padding(.horizontal,5)
        }
    }
    
    func fetchPosts() async{
        do {
            var query: Query!
            query = Firestore.firestore().collection("Posts").whereField("userid", isEqualTo: user.userid).limit(to: 10)
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
