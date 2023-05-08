import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore
import FirebaseStorage
import AVKit

struct PostCardView: View {
    var post: Post
    var onUpdate: (Post)->()
    var onDelete: ()->()
    
    @State private var docListener: ListenerRegistration?
    @State private var isPlaying: Bool = false
    @State private var player: AVPlayer?
    
    @AppStorage("user_UID") private var userUID: String = ""
    
    var body: some View {
        HStack(alignment: .top, spacing: 12){
            NavigationLink(destination: OtherProfileView(username: post.userName)) {
                WebImage(url: post.iconURL)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 35, height: 35)
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 6){
                NavigationLink(destination: OtherProfileView(username: post.userName)) {
                    Text(post.userName)
                        .font(.callout)
                        .fontWeight(.semibold)
                }
                Text(post.publishedDate.formatted(date: .numeric, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(post.text)
                    .textSelection(.enabled)
                    .padding(.vertical,8)
                
                if let postMediaURL = post.imageURL{
                    var justPicture = post.soundURL == nil
                    let justPictureBinded = Binding<Bool>(get: {return justPicture}, set: {newValue in justPicture = newValue})
                    
                    NavigationLink(destination: DetailView(postMediaURL: postMediaURL), isActive: justPictureBinded) {
                        GeometryReader { geometry in
                            let size = geometry.size
                            ZStack {
                                WebImage(url: postMediaURL)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: size.width, height: size.height)
                                    .overlay(Color.black.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                if let soundURL = post.soundURL{
                                    Button(action: {
                                        self.isPlaying.toggle()
                                        let playerItem: AVPlayerItem = AVPlayerItem(url: post.soundURL ?? URL(fileURLWithPath: ""))
                                        self.player = AVPlayer(playerItem: playerItem)
                                        self.player?.volume = 1
                                        self.player?.play()
                                    }) {
                                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(.white)
                                            .colorMultiply(.yellow)
                                    }
                                }
                            }
                        }
                        .frame(height: 200)
                    }
                    .navigationBarBackButtonHidden(false)
                    
                }
                
                PostInteration()
            }
        }
        .hAlign(.leading)
        .overlay(alignment: .topTrailing, content:{
            if post.userid == userUID{
                Button(role:.destructive,action:deletePost) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .rotationEffect(.init(degrees: 0))
                        .foregroundColor(.red)
                        .padding(8)
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

struct DetailView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State var postMediaURL: URL
    @State private var offset = CGSize.zero
    @State private var lastOffset = CGSize.zero
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var minScale: CGFloat = 1.0
    @State private var maxScale: CGFloat = 5.0
    @State private var isDragging = false
    
    var magnification: some Gesture {
        MagnificationGesture()
            .onChanged { state in
                adjustScale(from: state)
            }
            .onEnded { state in
                withAnimation {
                    validateScaleLimits()
                }
                lastScale = 1.0
            }
    }
    
    var body: some View {
        NavigationView{
            ZStack {
                WebImage(url: postMediaURL)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)

                    .gesture(magnification)
                    .gesture(TapGesture(count: 2)
                        .onEnded {
                            withAnimation{
                                scale = 1.0
                            }
                        }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                withAnimation{
                                    if scale > 1{
                                        offset = value.translation
                                    }
                                }
                            }
                            .onEnded { value in
                                if value.translation.width > UIScreen.main.bounds.width * 0.3 {
                                    presentationMode.wrappedValue.dismiss()
                                } else {
                                    withAnimation(.spring()) {
                                        offset = .zero
                                    }
                                }
                            }
                    )
                }
                
                Color.black.opacity(offset.width > 0 ? Double(offset.width / UIScreen.main.bounds.width) : 0)
                    .edgesIgnoringSafeArea(.all)
            }
    }
    
    func adjustScale(from state: MagnificationGesture.Value){
        let delta = state / lastScale
        scale *= delta
        lastScale = state
    }
    
    func adjustOffset(from value: DragGesture.Value) {
        let currentOffset = value.translation
        offset = CGSize(width: currentOffset.width + lastOffset.width, height: currentOffset.height + lastOffset.height)
    }
    
    func getMinimumScaleAllowed() -> CGFloat {
        return max(scale, minScale)
    }
    
    func getMaximumScaleAllowed() -> CGFloat {
        return min(scale, maxScale)
    }
    
    func validateScaleLimits(){
        scale = getMinimumScaleAllowed()
        scale = getMaximumScaleAllowed()
    }

    
    func resetImageState() {
        return withAnimation(.spring()){
            scale = 1
            offset = .zero
        }
    }
}
