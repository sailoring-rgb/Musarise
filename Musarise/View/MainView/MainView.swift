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
            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
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
