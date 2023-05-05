import SwiftUI

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
                    ToolbarItem(placement: .navigationBarTrailing){
                        NavigationLink{
                            SearchUserView()
                        } label:{
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
