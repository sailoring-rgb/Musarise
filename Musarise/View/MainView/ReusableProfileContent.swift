import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore
import FirebaseStorage
import PhotosUI
import FirebaseAuth

struct ReusableProfileContent: View {
    @State var user: User
    @Binding var posts: [Post]
    @State var isFetching: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var selectedImage: PhotosPickerItem?
    
    @AppStorage("user_profile_url") var downloadURL: URL?
    
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
                    .onTapGesture {
                        showImagePicker = true
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
                                    
                                    let userObject = User(username: user.username, userid: user.userid, email: user.email, iconURL: profileURL)
                                    
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
                                                let updatedPost = Post(text: post.text, userName: post.userName, userid: post.userid, iconURL: profileURL)
                                                
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
                    }
                    .hAlign(.leading)
                }
                if Auth.auth().currentUser?.email == user.email{
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
