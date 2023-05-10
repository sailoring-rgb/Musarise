import SwiftUI
import SDWebImageSwiftUI

struct PostsView: View {
    @State private var recentPosts: [Post] = []
    @State private var newPost : Bool = false
    
    var body: some View {
        NavigationStack {
            ReusablePostsContent(posts: $recentPosts)
                .hAlign(.center).vAlign(.center)
                .overlay(alignment: .bottomTrailing){
                    Button{
                        newPost.toggle()
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(13)
                            .background(.yellow, in: Circle())
                    }
                    .padding(15)
                }
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarLeading) {
                        NavigationLink(destination: ChallengeView()) {
                            Image(systemName: "map")
                                .tint(.black)
                                .scaleEffect(0.9)
                        }
                    }
                    ToolbarItem(placement: .principal) {
                        WebImage(url: URL(string:"https://firebasestorage.googleapis.com/v0/b/csound-967d4.appspot.com/o/General%2Flogo.png?alt=media&token=e63ff60f-49d4-473d-86b2-afbd88ae5000"))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(7)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: SearchUserView()) {
                            Image(systemName: "magnifyingglass")
                                .tint(.black)
                                .scaleEffect(0.9)
                        }
                    }
                })
                .fullScreenCover(isPresented: $newPost){
                    NewPostView{ post in
                        recentPosts.insert(post, at: 0)
                    }
                }
        }
        .navigationTitle("Recent Posts")
    }
}

struct PostsView_Previews: PreviewProvider {
    static var previews: some View {
        PostsView()
    }
}
