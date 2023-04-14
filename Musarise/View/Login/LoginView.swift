import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

struct LoginView: View{
    
    @State var email: String = ""
    @State var password: String = ""
    @State var userName: String = ""
    @State var createAccount: Bool = false
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false

    @AppStorage("log_status") var logStatus: Bool = false
    
    var body: some View{
        VStack(spacing: 10){
            Text("Let's sign you in..")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            Text("Welcome back!")
                .font(.title3)
                .hAlign(.leading)
            VStack(spacing: 12){
                TextField("Email / Username", text: $email)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                SecureField("Password", text: $password)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                Button(action: login){
                    Text("Sign in")
                        .foregroundColor(.white)
                        .hAlign(.center)
                        .fillView(.black)
                } .padding(.top, 10)
            }
            
            HStack{
                Text("Not a member yet?")
                    .foregroundColor(.gray)
                Button("Create account"){
                    createAccount.toggle()
                } .fontWeight(.bold)
                    .foregroundColor(.black)
            } .font(.callout)
                .vAlign(.bottom)
        } .vAlign(.center)
            .padding(15)
            .overlay(content: {
                LoadingView(show: $isLoading)
            })
            .fullScreenCover(isPresented: $createAccount){
                RegisterView()
            }
            .alert(errorMessage, isPresented: $showError, actions: {})
    }
    
    func login(){
            isLoading = true
            closeKeyboard()
            Task{
                do {
                    if isValidEmail(email) {
                        try await Auth.auth().signIn(withEmail: email, password: password)
                        print("User Found")
                        logStatus = true
                        isLoading = false
                    }
                    else {
                        guard let emailReturned = try await getEmailFromUsername(username: email) else { return }
                        self.email = emailReturned
                        try await Auth.auth().signIn(withEmail: email, password: password)
                        print("User Found")
                        logStatus = true
                        isLoading = false
                    }
                } catch {
                    await setError(error)
                    isLoading = false
                }
            }
        }

    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    func getEmailFromUsername(username: String) async throws -> String? {
        let userReference = Firestore.firestore().collection("Users")
        let query = userReference.whereField("username", isEqualTo: username)
        let snapshot = try await query.getDocuments()

        guard let email = snapshot.documents.first?.data()["email"] as? String else { return nil }
        
        return email
    }

    func setError(_ error: Error) async {
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
}

struct LoginView_Previews: PreviewProvider{
    static var previews: some View{
        ContentView()
    }
}
