import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

struct OtherProfileView: View {
    var username: String
    @State private var myProfile: User?
    @State private var posts: [Post] = []
    @AppStorage("log_status") var logStatus: Bool = false
    @State var errorMessage: String = ""
    @State var showError: Bool = false
    @State var isLoading: Bool = false

    var body: some View {

        NavigationStack{
            VStack{
                if let myProfile {
                    ReusableProfileContent(user: myProfile, posts: $posts)
                        .refreshable {
                            self.myProfile = nil
                            await fetchUserData(username: username)
                        }
                } else {
                    ProgressView()
                }
            }
            .padding(.horizontal,20)
            .navigationTitle("User Profile")
        }
        .overlay{
            LoadingView(show: $isLoading)
        }
        .alert(errorMessage, isPresented: $showError){}
        .task {
            if myProfile != nil {return}
            await fetchUserData(username: username)
        }
        
        
    }
    
    func getUserFromUsername(username: String) async throws -> User? {
        let userReference = Firestore.firestore().collection("Users")
        let query = userReference.whereField("username", isEqualTo: username)
        let snapshot = try await query.getDocuments()
        guard let userObject = snapshot.documents.first else {
            return nil
        }
        let user = try userObject.data(as: User.self)
        return user
    }
    
    func fetchUserData(username: String) async{
        do{
            guard let user = try await getUserFromUsername(username: username) else {return}
            
            await MainActor.run(body: {
                myProfile = user
            })
        } catch {
            await setError(error)
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

struct OtherProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
