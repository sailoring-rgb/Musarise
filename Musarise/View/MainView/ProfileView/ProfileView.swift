import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

struct ProfileView: View {
    @State private var myProfile: User?
    @State private var posts: [Post] = []
    @AppStorage("log_status") var logStatus: Bool = false
    @State var errorMessage: String = ""
    @State var showError: Bool = false
    @State var isLoading: Bool = false
    @AppStorage("isDarkMode") var isDarkMode: Bool = false
    
    var body: some View {
        NavigationStack{
            VStack{
                if let myProfile {
                    ReusableProfileContent(user: myProfile, posts: $posts)
                        .refreshable {
                            self.myProfile = nil
                            await fetchUserData()
                        }
                } else {
                    ProgressView()
                }
            }
            .padding(.horizontal,20)
            .navigationTitle("My Profile")
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing){
                    Menu{
                        Button("Logout", action: logOutUser)
                        Button("Delete Account",role: .destructive, action: deleteAccount)
                        Toggle("Dark Mode", isOn: $isDarkMode)
                        
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.init(degrees: 90))
                            .tint(.black)
                            .scaleEffect(0.8)
                    }
                }
            }
        }
        .overlay{
            LoadingView(show: $isLoading)
        }
        .alert(errorMessage, isPresented: $showError){}
        .task {
            if myProfile != nil {return}
            await fetchUserData()
        }

            
    }
    
    func fetchUserData() async{
        guard let userID = Auth.auth().currentUser?.uid else{return}
        guard let user = try? await Firestore.firestore().collection("Users").document(userID).getDocument(as: User.self) else{return}
        await MainActor.run(body: {
            myProfile = user
        })
    }
    
    func logOutUser(){
        try? Auth.auth().signOut()
        logStatus = false
    }
    
    func deleteAccount(){
        isLoading = true
        Task{
            do{
                guard let userID = Auth.auth().currentUser?.uid else {return}
                let reference = Storage.storage().reference().child("Profile_Pics").child(userID)
                try await reference.delete()
                try await Firestore.firestore().collection("Users").document(userID).delete()
                try await Auth.auth().currentUser?.delete()
                logStatus = false
            }catch{
                await setError(error)
            }
        }
    }
    
    func setError(_ error: Error) async {
        await MainActor.run(body: {
            isLoading = false
            errorMessage = error.localizedDescription
            showError.toggle()
        })
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
