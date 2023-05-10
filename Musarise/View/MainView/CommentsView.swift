import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore
import FirebaseStorage

struct CommentsView: View {
    @State var post: Post?
    @State var newCommentText: String = ""
    @AppStorage("user_UID") private var userUID: String = ""
    @AppStorage("user_profile_url") var userIconURL: URL?
    @AppStorage("user_name") var userName: String = ""
    @State var isFetching: Bool = false
    
    var body: some View {
        VStack {
            ScrollView {
                if isFetching{
                    ProgressView()
                        .padding(.top, 20)
                } else {
                    if let post = post{
                        if let comments = post.comments{
                            ForEach(comments, id: \.self) { (comment:Comment) in
                                HStack {
                                    WebImage(url: comment.userIconUrl)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 35, height: 35)
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(comment.userName)
                                            .fontWeight(.semibold)
                                        
                                        Text(comment.text)
                                        
                                        Text(comment.publishedDate.formatted(date: .numeric, time: .shortened))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .frame(width: UIScreen.main.bounds.width - 25,alignment: .topLeading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
            .refreshable {
                isFetching = true
                await fetchPost()
            }
            HStack {
                WebImage(url: userIconURL)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 35, height: 35)
                    .clipShape(Circle())
                    .padding(.leading,8)
                TextField("Add a comment...", text: $newCommentText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(4)
                Button(action: postComment) {
                    Text("Post")
                        .fontWeight(.semibold)
                        .padding(8)
                }
                .padding(.leading,8)
                .foregroundColor(.white)
                .background(Color.yellow)
                .cornerRadius(15)
            }
            .background(Color.gray.opacity(0.1))
        }
        .navigationBarTitle("Comments")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func postComment(){
        Task{
            guard let post = post else {return}
            guard let postID = post.id else {return}
            guard let userIconURL = userIconURL else {return}

            try await Firestore.firestore().collection("Posts").document(postID).updateData([
                "comments": FieldValue.arrayUnion([
                        ["userIconUrl": userIconURL.absoluteString,
                         "userName": userName,
                         "text": newCommentText,
                         "publishedDate": Date()]
                    ])
            ])
            await fetchPost()
            self.newCommentText = ""
        }
    }

    func fetchPost() async {
        guard let post = post else {return}
        guard let postID = post.id else{return}
        guard let post = try? await Firestore.firestore().collection("Posts").document(postID).getDocument(as: Post.self) else{return}
        await MainActor.run(body: {
            self.post = post
            isFetching = false
        })
    }
}

struct CommentsView_Previews: PreviewProvider {
    static var previews: some View {
        CommentsView()
    }
}
