import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore
import FirebaseStorage

struct PostCardView: View {
    var post: Post
    var onUpdate: (Post)->()
    var onDelete: ()->()
    
    @AppStorage("user_UID") private var userUID: String = ""
    @State private var docListener: ListenerRegistration?
    var body: some View {
        HStack(alignment: .top, spacing: 12){
            WebImage(url: post.profileURL)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 35, height: 35)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6){
                Text(post.userName)
                    .font(.callout)
                    .fontWeight(.semibold)
                Text(post.publishedDate.formatted(date: .numeric, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(post.text)
                    .textSelection(.enabled)
                    .padding(.vertical,8)
                
                if let postMediaURL = post.imageURL{
                    GeometryReader{
                        let size = $0.size
                        WebImage(url: postMediaURL)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .frame(height: 200)
                }
                
                PostInteration()
            }
        }
        .hAlign(.leading)
        .overlay(alignment: .topTrailing, content:{
            if post.userid == userUID{
                Menu{
                    Button("Delete",role:.destructive,action:deletePost)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .rotationEffect(.init(degrees: -90))
                        .foregroundColor(.black)
                        .padding(8)
                        .contentShape(Rectangle())
                }
            }
        })
        .onAppear{
            if docListener == nil{
                guard let postid = post.id else {return}
                docListener = Firestore.firestore().collection("Posts").document(postid).addSnapshotListener({
                    snapshot, error in
                    if let snapshot{
                        if snapshot.exists{
                            if let updatedPost = try? snapshot.data(as: Post.self){
                                onUpdate(updatedPost)
                            }
                        } else {
                            onDelete()
                        }
                    }
                })
            }
        }
        
        .onDisappear(){
            if let docListener{
                docListener.remove()
                self.docListener = nil
            }
        }
    }
    
    @ViewBuilder
    func PostInteration()->some View{
        HStack(spacing: 6){
            Button(action: likePost){
                Image(systemName: post.likedIDs.contains(userUID) ? "heart.fill": "heart")
            }
            
            Text("\(post.likedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .foregroundColor(.black)
        .padding(.vertical,8)
    }
    
    func likePost(){
        Task{
            guard let postid = post.id else {return}
            if post.likedIDs.contains(userUID){
                try await Firestore.firestore().collection("Posts").document(postid).updateData([
                    "likedIDs": FieldValue.arrayRemove([userUID])
                ])
            } else {
                try await Firestore.firestore().collection("Posts").document(postid).updateData([
                    "likedIDs": FieldValue.arrayUnion([userUID])
                ])
            }
        }
    }
    
    func deletePost(){
        Task{
            do{
                print("deleting post: "+post.imageReferenceID)
                if post.imageReferenceID != "" {
                    try await Storage.storage().reference().child("Post_media").child(post.imageReferenceID).delete()
                }
                guard let postid = post.id else{return}
                try await Firestore.firestore().collection("Posts").document(postid).delete()
            }catch{
                print(error.localizedDescription)
            }
        }
    }
}
