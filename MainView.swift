//
//  MainView.swift
//  Musarise
//
//  Created by annaphens on 13/04/2023.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView{
            Text("Feed")
                .tabItem {
                    Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled")
                    Text("Feed")
                }
            Text("Playground")
                .tabItem {
                    Image(systemName: "play.square.fill")
                    Text("Playground")
                }
            ProfileView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Profile")
                }
        }
        .tint(.black)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
