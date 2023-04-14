//
//  PostsView.swift
//  Musarise
//
//  Created by annaphens on 14/04/2023.
//

import SwiftUI

struct PostsView: View {
    @State private var newPost : Bool = false
    var body: some View {
        Text("New Post?")
            .hAlign(.center).vAlign(.center)
            .overlay(alignment: .bottomTrailing){
                Button{
                    newPost.toggle()
                } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(13)
                        .background(.black, in: Circle())
                }
                .padding(15)
            }
            .fullScreenCover(isPresented: $newPost){
                NewPostView{ post in }
            }
    }
}

struct PostsView_Previews: PreviewProvider {
    static var previews: some View {
        PostsView()
    }
}
