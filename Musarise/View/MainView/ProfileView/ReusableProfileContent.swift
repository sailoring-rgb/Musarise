import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

struct ReusableProfileContent: View {
    @State var user: User
    @Binding var posts: [Post]
    @State var isFetching: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var showModal: Bool = false
    @State private var isFollowing: Bool = false
    @State private var selectedImage: PhotosPickerItem?
    
    @AppStorage("user_profile_url") var downloadURL: URL?
    @AppStorage("user_UID") var userUID: String = ""
    
    var body: some View {
        ZStack {
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
                        .onTapGesture {
                            if user.userid  == userUID{
                                showImagePicker = true
                            }
                        }
                        .photosPicker(isPresented: $showImagePicker, selection: $selectedImage)
                        .onChange(of: selectedImage){
                            newValue in
                            if let newValue{
                                Task{
                                    do {
                                        guard let imageData = try await newValue.loadTransferable(type: Data.self) else { return }
                                        
                                        let tempDirectory = FileManager.default.temporaryDirectory
                                        let tempFileURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("png")
                                        
                                        try imageData.write(to: tempFileURL)
                                        
                                        // Upload the image to Firebase Storage
                                        let picsStorageReference = Storage.storage().reference().child("Profile_Pics").child(user.userid)
                                        let _ = try await picsStorageReference.delete()
                                        let _ = try await picsStorageReference.putDataAsync(imageData)
                                        
                                        let profileURL = try await picsStorageReference.downloadURL()
                                        
                                        let userObject = User(username: user.username, userid: user.userid, email: user.email, iconURL: profileURL,following:user.following,followers:user.followers)
                                        
                                        let _ = try Firestore.firestore().collection("Users").document(user.userid).setData(from: userObject, completion: {
                                            error in
                                            if error == nil {
                                                print("Saved successfully!")
                                                downloadURL = profileURL
                                            }
                                        }
                                        )
                                        
                                        var refreshedPosts: [Post] = []
                                        
                                        Firestore.firestore().collection("Posts").whereField("userid", isEqualTo: user.userid).getDocuments() { (querySnapshot, error) in
                                            guard let querySnapshot = querySnapshot else {
                                                print("Error getting documents: \(error!)")
                                                return
                                            }
                                            
                                            for document in querySnapshot.documents {
                                                let post = try? document.data(as: Post.self)
                                                if let post = post {
                                                    let updatedPost = Post(text: post.text, imageURL: post.imageURL, imageReferenceID: post.imageReferenceID, userName: post.userName, userid: post.userid, iconURL: profileURL)
                                                    
                                                    refreshedPosts.append(updatedPost)
                                                    
                                                    let _ = try? Firestore.firestore().collection("Posts").document(document.documentID).setData(from: updatedPost) { error in
                                                        if let error = error {
                                                            print("Error updating document: \(error)")
                                                        } else {
                                                            print("Document successfully updated")
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        await fetchPosts()
                                        
                                        await MainActor.run(body: {
                                            user.iconURL = profileURL
                                        })
                                    } catch {
                                        print(error)
                                    }
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6){
                            Text(user.username)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            HStack{
                                Text(String(posts.count) + " posts")
                                    .fontWeight(.semibold)
                                    .padding(.horizontal,5)
                                    .padding(.vertical,10)
                                
                                Button(action: {
                                    withAnimation{
                                        self.showModal = true
                                    }
                                    self.isFollowing = false
                                }){
                                    if user.followers.count == 1 {
                                        Text(String(user.followers.count) + " follower")
                                            .fontWeight(.semibold)
                                            .padding(.horizontal,5)
                                            .padding(.vertical,10)
                                    } else {
                                        Text(String(user.followers.count) + " followers")
                                            .fontWeight(.semibold)
                                            .padding(.horizontal,5)
                                            .padding(.vertical,10)
                                    }
                                }
                                
                                Button(action: {
                                    withAnimation{
                                        self.showModal = true
                                    }
                                    self.isFollowing = true
                                }){
                                    Text(String(user.following.count) + " following")
                                        .fontWeight(.semibold)
                                        .padding(.horizontal,5)
                                        .padding(.vertical,10)
                                }
                                
                            }
                            .font(.system(size: fontSize()))
                            
                            
                            if user.userid != userUID{
                                Button(action: {
                                    if user.followers.contains(userUID){
                                        Task{await unfollow()}
                                    } else if user.id != userUID{
                                        Task{await follow()}
                                        
                                    }
                                    
                                }) {
                                    HStack {
                                        Image(systemName: "person.badge.plus.fill")
                                        if user.followers.contains(userUID){
                                            Text("Unfollow")
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                            
                                        } else if user.id != userUID{
                                            Text("Follow")
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                            
                                        }
                                        
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.yellow)
                                    .cornerRadius(15)
                                }
                            }
                        }
                        .hAlign(.leading)
                    }
                    .padding(.top, 20)
                    
                    Divider()
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    
                    if user.userid == userUID{
                        Text("My Posts")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .hAlign(.leading)
                            .padding(.vertical,15)
                    } else {
                        Text("Their Posts")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .hAlign(.leading)
                            .padding(.vertical,15)
                    }
                    
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
            }
            .refreshable {
                isFetching = true
                posts = []
                await fetchPosts()
                await fetchUserData()
            }
            .task {
                guard posts.isEmpty else {return}
                await fetchPosts()
            }
            
            if showModal{
                GeometryReader{geo in
                    if !isFollowing{
                        FollowersListView(users: user.followers, isFollowing: $isFollowing)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .position(x: geo.size.width/2, y: geo.size.height/2)
                    } else {
                        FollowersListView(users: user.following, isFollowing: $isFollowing)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .position(x: geo.size.width/2, y: geo.size.height/2)
                    }
                }
                .background(Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        self.showModal = false
                    }
                    .frame(width: 700)
                )
            }
        }
        .frame(maxWidth: .infinity)
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
    
    func fetchUserData() async{
        guard let user = try? await Firestore.firestore().collection("Users").document(userUID).getDocument(as: User.self) else{return}
        await MainActor.run(body: {
            self.user = user
        })
    }
    
    func follow() async{
        // update selected user followers
        user.followers.append(userUID)
        Firestore.firestore().collection("Users").document(user.userid).updateData(["followers": user.followers]) { error in
               if let error = error {
                   print("Erro ao atualizar a lista de seguidores: \(error.localizedDescription)")
               } else {
                   print("Você passou a estar na lista de seguidos do usuário com sucesso")
               }
           }
        
        // update my user following
        let myFollowingRef = Firestore.firestore().collection("Users").document(userUID)

        myFollowingRef.updateData([
            "following": FieldValue.arrayUnion([user.userid])
        ]) { error in
            if let error = error {
                print("Erro ao seguir usuário: \(error.localizedDescription)")
                return
            }
            
            print("Usuário adicionado a sua lista de seguidos")
        }
    }
    
    func unfollow() async{
        // update selected user followers
        user.followers.removeAll { $0 == userUID}
        
        Firestore.firestore().collection("Users").document(user.userid).updateData(["followers": user.followers]) { error in
               if let error = error {
                   print("Erro ao atualizar a lista de seguidores: \(error.localizedDescription)")
               } else {
                   print("Você deixou de seguir o usuário com sucesso")
               }
           }
        
        // update my user following
        let myFollowingRef = Firestore.firestore().collection("Users").document(userUID)

        myFollowingRef.updateData([
            "following": FieldValue.arrayRemove([user.userid])
        ]) { error in
            if let error = error {
                print("Erro ao seguir usuário: \(error.localizedDescription)")
                return
            }
            
            print("Usuário removido da sua lista de seguidos")
        }    }
}

struct Previews_ReusableProfileContent_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
