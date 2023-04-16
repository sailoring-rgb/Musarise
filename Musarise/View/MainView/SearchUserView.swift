//
//  SearchUserView.swift
//  Musarise
//
//  Created by parola on 15/04/2023.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import SDWebImageSwiftUI

struct SearchUserView: View {
    @State private var fetchedUsers: [User] = []
    @State private var searchText: String = ""
    @Environment(\.dismiss) private var dismiss
    @State private var posts: [Post] = []
    
    var body: some View {
        List{
            ForEach(fetchedUsers) { user in
                NavigationLink(destination: OtherProfileView(username: user.username)) {
                    HStack{
                        WebImage(url: user.iconURL)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 35, height: 35)
                            .clipShape(Circle())
                        
                        Text(user.username)
                            .font(.callout)
                            .hAlign(.leading)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Search User" )
        .searchable(text: $searchText)
        .onSubmit(of: .search, {
            Task{await searchUsers()}
        })
        .onChange(of: searchText, perform: { newValue in
            if newValue.isEmpty{
                fetchedUsers = []
            }
        })
    }
        
    func searchUsers()async{
        do{
            let documents = try await Firestore.firestore().collection("Users")
                .whereField("username", isGreaterThanOrEqualTo: searchText)
                .getDocuments()
            
            let users = try documents.documents.compactMap { doc -> User? in
                try doc.data(as: User.self)
            }
            
            await MainActor.run(body:{
                fetchedUsers = users
            })
        }catch{
            print(error.localizedDescription)
        }
    }
}

struct SearchUserView_Previews: PreviewProvider {
    static var previews: some View {
        SearchUserView()
    }
}
