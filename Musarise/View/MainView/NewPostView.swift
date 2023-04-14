import SwiftUI
import PhotosUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

struct NewPostView: View {
    var onPost: (Post)->()
    @State private var text: String = ""
    @State private var imageData: Data?
    
    @AppStorage("user_profile_url") private var profileURL: URL?
    @AppStorage("user_name") private var userName: String = ""
    @AppStorage("user_UID") private var userUID: String = ""
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var photoItem: PhotosPickerItem?
    @FocusState private var showKeyboard: Bool
    
    var body: some View {
        VStack{
            HStack{
                Menu{
                    Button("Cancel", role: .destructive){
                        dismiss()
                    }
                } label: {
                    Text("Cancel")
                    .font(.callout)
                    .foregroundColor(.black)
                }
                .hAlign(.leading)
                
                Button(action: createPost){
                    Text("Post")
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(.horizontal,20)
                        .padding(.vertical,6)
                        .background(.black, in: Capsule())
                }
            }
            .padding(.horizontal,15)
            .padding(.vertical,10)
            .background{
                Rectangle()
                    .fill(.gray.opacity(0.05))
                    .ignoresSafeArea()
            }
            
            ScrollView(.vertical, showsIndicators: false){
                VStack(spacing: 15){
                    TextField("What have you been listening to?", text: $text, axis: .vertical)
                        .focused($showKeyboard)
                    
                    if let imageData, let image = UIImage(data: imageData){
                        GeometryReader{
                            let size = $0.size
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: size.width, height: size.height)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(alignment: .topTrailing){
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.25)){
                                            self.imageData = nil
                                        }
                                    } label: {
                                        Image(systemName: "trash")
                                            .fontWeight(.bold)
                                            .tint(.red)
                                    }
                                    .padding(10)
                                }
                        }
                        .clipped()
                        .frame(height: 220)
                    }
                }
                .padding(15)
            }
            
            Divider()
            
            HStack{
                Button{
                    showImagePicker.toggle()
                } label: {
                    Image(systemName: "music.note.house")
                        .font(.title3)
                }
                .hAlign(.leading)
                
                Button("Done"){
                    showKeyboard = false
                }
            }
            .foregroundColor(.black)
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
        }
        .vAlign(.top)
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem){ newValue in
            if let newValue {
                Task{
                    if let rawImageData = try? await newValue.loadTransferable(type: Data.self), let image = UIImage(data: rawImageData), let compressedImageData = image.jpegData(compressionQuality: 0.5){
                        await MainActor.run(body: {
                            imageData = compressedImageData
                            photoItem = nil
                        })
                    }
                }
            }
        }
        .alert(errorMessage, isPresented: $showError, actions: {})
        .overlay{
            LoadingView(show: $isLoading)
        }
    }
    
    func createPost(){
        isLoading = true
        showKeyboard = false
        Task{
            do{
                guard let profileURL = profileURL else {return}
                //guard let userid = Auth.auth().currentUser?.uid else { return }
                //print(userid)
                let imageReferenceID = "\(userUID)\(Date())"
                let storageReference = Storage.storage().reference().child("Post_media").child(imageReferenceID)
                print("creating post: "+imageReferenceID)
                if let imageData {
                    let _ = try await storageReference.putDataAsync(imageData)
                    let downloadURL = try await storageReference.downloadURL()
                    
                    let post = Post(text: text, imageURL: downloadURL, imageReferenceID: imageReferenceID, userName: userName, userid: userUID, profileURL: profileURL)
                    try await createDocAtFirebase(post)
                }
                else {
                    let post = Post(text: text, userName: userName, userid: userUID, profileURL: profileURL)
                    try await createDocAtFirebase(post)
                }
            } catch {
                await setError(error)
            }
        }
    }
    
    func createDocAtFirebase(_ post: Post) async throws{
        let doc = Firestore.firestore().collection("Posts").document()
        let _ = try doc.setData(from: post, completion: {
            error in if error == nil {
                isLoading = false
                var updatedPost = post
                updatedPost.id = doc.documentID
                onPost(updatedPost)
                dismiss()
            }
        })
    }
    
    func setError(_ error: Error) async {
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
        })
    }
}

struct NewPostView_Previews: PreviewProvider {
    static var previews: some View {
        NewPostView{ _ in
            
        }
    }
}
