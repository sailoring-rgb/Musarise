import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore


struct RegisterView: View{
    
    @State var email: String = ""
    @State var password: String = ""
    @State var userName: String = ""
    @State var profileIcon: Data?
    @Environment(\.dismiss) var dismiss
    @State var showImagePicker: Bool = false
    @State var photoItem: PhotosPickerItem?
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false
    
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var downloadURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    
    var body: some View{
        VStack(spacing: 10){
            Text("Let's create your account..")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            Text("Welcome back!")
                .font(.title3)
                .hAlign(.leading)
            VStack(spacing: 12){
                ZStack{
                    if let profileIcon, let image = UIImage(data: profileIcon){
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Image("NullProfile")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                } .frame(width: 115, height: 115)
                    .clipShape(Circle())
                    .contentShape(Circle())
                    .onTapGesture {
                        showImagePicker.toggle()
                    }
                    .padding(.top, 25)
                
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                TextField("Username", text: $userName)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                SecureField("Password", text: $password)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                Button(action: register){
                    Text("Sign up")
                        .foregroundColor(.white)
                        .hAlign(.center)
                        .fillView(.black)
                }
                .disableOpacity(userName == "" || email == "" || password == "" /*|| profileIcon == nil*/)
                .padding(.top, 10)
            }
            
            HStack{
                Text("Already a member?")
                    .foregroundColor(.gray)
                Button("Sign in"){
                    dismiss()
                } .fontWeight(.bold)
                    .foregroundColor(.black)
            } .font(.callout)
                .vAlign(.bottom)
        } .vAlign(.top)
            .padding(15)
            .overlay(content: {
                LoadingView(show: $isLoading)
            })
            .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem){
            newValue in
            if let newValue{
                Task{
                    do{
                        guard let imageData = try await newValue.loadTransferable(type: Data.self) else { return }
                        await MainActor.run(body: {
                            profileIcon = imageData
                        })
                    }
                }
            }
        }
        .alert(errorMessage, isPresented: $showError, actions: {})
    }
    
    func register(){
        isLoading = true
        closeKeyboard()
        Task{
            do {
                // Step 1: Creating Firebase Account
                try await Auth.auth().createUser(withEmail: email, password: password)
                
                // Step 2: Uploading Profile Photo Into Firebase Storage
                guard let userid = Auth.auth().currentUser?.uid else { return }
                guard let iconData = profileIcon else { return }
                let storageReference = Storage.storage().reference().child("Profile_Pics").child(userid)
                let _ = try await storageReference.putDataAsync(iconData)
                
                // Step 3: Download Icon URL
                let profileURL = try await storageReference.downloadURL()
                
                // Step 4: Create a User Firestore Object
                let userObject = User(username: userName, userid: userid, email: email, iconURL: profileURL,following: [], followers: [])
                
                // Step 5: Save User in Database
                let _ = try Firestore.firestore().collection("Users").document(userid).setData(from: userObject, completion: {
                        error in
                        if error == nil {
                            print("Saved successfully!")
                            userNameStored = userName
                            userUID = userid
                            downloadURL = profileURL
                            logStatus = true
                        }
                    }
                )
            } catch {
                // Delete account in case of failure
                try await Auth.auth().currentUser?.delete()
                await setError(error)
            }
        }
    }
    
    func setError(_ error: Error) async {
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
