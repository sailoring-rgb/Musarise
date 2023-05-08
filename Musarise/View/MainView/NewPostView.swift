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
    
    @State private var showGarage: Bool = false
    @State private var sounds: [PlaygroundSound] = []
    @State private var soundURLSelected: URL?
    
    var body: some View {
        ZStack{
            VStack{
                HStack{
                    Button("Cancel", role: .destructive){
                        dismiss()
                    }
                    .hAlign(.leading)
                    
                    Button(action: createPost){
                        Text("Post")
                            .font(.callout)
                            .foregroundColor(.white)
                            .padding(.horizontal,20)
                            .padding(.vertical,6)
                            .background(notValidPost(type: 0).wrappedValue ? .gray : .black, in: Capsule())
                    }
                    .disabled(notValidPost(type: 0).wrappedValue ? true : false)
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
                        
                        if let soundSelected = soundURLSelected{
                            let sound = getSound(soundURLSelected: soundSelected)
                            if let sound = sound{
                                HStack(){
                                    Text(sound.soundTitle)
                                        .font(.system(size: fontSize()))
                                        .foregroundColor(Color.gray)
                                        .padding(.horizontal, 3)
                                        .padding(.top, 8)
                                    
                                    Text(sound.instrumentIcon)
                                        .font(.system(size: fontSize()))
                                        .foregroundColor(Color.gray)
                                        .padding(.top, 5)
                                }
                                .hAlign(.trailing)
                            }
                        }
                    }
                    .padding(15)
                }
                
                Divider()
                
                HStack{
                    Button{
                        showImagePicker.toggle()
                    } label: {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title3)
                    }
                    .hAlign(.leading)
                    
                    Button{
                        showGarage.toggle()
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
            
            if showGarage{
                GeometryReader{geo in
                    UserGarageView()
                        .position(x: geo.size.width/2, y: geo.size.height/2)
                }
                .background(Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        self.showGarage = false
                    }
                    .frame(width: 700)
                )
                .task {
                    await self.fetchUserSounds()
                }
            }
        }
        .alert("An audio requires an icon! Please, select a photo.", isPresented: notValidPost(type: 1), actions: {})
    }
    
    func notValidPost(type: Int) -> Binding<Bool> {
        // Condição para lançar um erro caso um sound seja selecionado sem um icon
        if type == 1{
            return Binding<Bool>(get: {
                return self.soundURLSelected != nil && self.imageData == nil
            }, set: { _ in })
        }
        // Condição para desativar o botão "Post" caso o post não seja válido
        else{
            return Binding<Bool>(get: {
                return (self.imageData == nil && self.text == "") || (self.soundURLSelected != nil && self.imageData == nil)
            }, set: { _ in })
        }
    }
    
    func createPost(){
        isLoading = true
        showKeyboard = false
        Task{
            do{
                guard let profileURL = profileURL else {return}
                
                let imageReferenceID = "\(userUID)\(Date())"
                let storageReference = Storage.storage().reference().child("Post_media").child(imageReferenceID)

                // have both image and sound
                if let imageData, let soundURLSelected {
                    let _ = try await storageReference.putDataAsync(imageData)
                    let downloadURL = try await storageReference.downloadURL()
                    let post = Post(text: text, imageURL: downloadURL, imageReferenceID: imageReferenceID, userName: userName, userid: userUID, iconURL: profileURL, soundURL: self.soundURLSelected)
                    try await createDocAtFirebase(post)
                }
                // have just image
                else if let imageData{
                    let _ = try await storageReference.putDataAsync(imageData)
                    let downloadURL = try await storageReference.downloadURL()
                    let post = Post(text: text, imageURL: downloadURL, imageReferenceID: imageReferenceID, userName: userName, userid: userUID, iconURL: profileURL)
                    try await createDocAtFirebase(post)
                }
                // do not have image and sound
                else {
                    let post = Post(text: text, userName: userName, userid: userUID, iconURL: profileURL)
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
    
    func fetchUserSounds() async{
        do{
            var query: Query!
            query = Firestore.firestore().collection("Playground").whereField("userid", isEqualTo: userUID)
            let docs = try await query.getDocuments()
            let fetchedSounds = docs.documents.compactMap{ doc -> PlaygroundSound? in
                try? doc.data(as: PlaygroundSound.self)
            }
            
            await MainActor.run {
                self.sounds = fetchedSounds
                print(self.sounds)
            }
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func getSound(soundURLSelected: URL) -> PlaygroundSound?{
        for sound in sounds{
            if sound.soundURL == soundURLSelected{
                return sound
            }
        }
        return nil
    }
    
    @ViewBuilder
    func UserGarageView()->some View {
        NavigationView{
            ScrollView{
                LazyVGrid(columns: [GridItem()],spacing: 10){
                    ForEach(sounds){ sound in
                        VStack(alignment: .leading) {
                            Text(sound.instrumentIcon+"   "+sound.instrumentName)
                                .font(.system(size: 16.0))
                                .foregroundColor(Color.black)
                                .bold()
                                .padding(.horizontal, 10)
                                .padding(.top,3)
                            Text(sound.soundTitle)
                                .font(.system(size: 15.0))
                                .foregroundColor(Color.black)
                                .bold()
                                .padding(.horizontal, 10)
                                .padding(.top,3)
                            Text(sound.publishedDate.formatted(date: .numeric, time: .shortened))
                                .font(.system(size: 12.0))
                                .foregroundColor(Color.gray)
                                .padding(.horizontal, 10)
                                .padding(.top,0.5)
                            Text(sound.soundDescription)
                                .font(.system(size: 14.0))
                                .foregroundColor(Color.black)
                                .padding(.horizontal, 10)
                                .padding(.top,6)
                            
                        }
                        .frame(width: UIScreen.main.bounds.size.width / 1.3,alignment: .topLeading)
                        .gesture(TapGesture().onEnded{
                            self.soundURLSelected = sound.soundURL
                            self.showGarage = false
                        })
                        Divider()
                            .padding(.horizontal,5)
                            .padding(.bottom, 20)
                            .padding(.top, 10)
                    }
                }
            }
            .navigationBarTitle("Garage")
            .navigationBarTitleDisplayMode(.inline)
        }
        .background(Color.white)
        .cornerRadius(20)
        .frame(width: UIScreen.main.bounds.size.width / 1.2, height: UIScreen.main.bounds.size.height / 1.5)
    }
}

struct NewPostView_Previews: PreviewProvider {
    static var previews: some View {
        NewPostView{ _ in
        }
    }
}
