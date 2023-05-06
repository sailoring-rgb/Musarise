import SwiftUI

struct MainView: View {
    var body: some View {
        TabView{
            PostsView()
                .tabItem {
                    Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled")
                    Text("Feed")
                }
            PlaygroundView()
                .tabItem {
                    Image(systemName: "play.square.fill")
                    Text("Playground")
                }
            GarageView()
                .tabItem {
                    Image(systemName: "music.note")
                    Text("Garage")
                }
            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text("Profile")
                }
        }
        .tint(.black)
        .background(Color.gray.opacity(0.1))
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
