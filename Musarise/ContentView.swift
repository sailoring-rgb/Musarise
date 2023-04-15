import SwiftUI

struct ContentView: View {
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("isDarkMode") var isDarkMode: Bool = false
    var body: some View {
        if logStatus{
            MainView()
                .preferredColorScheme(isDarkMode ? .dark: .light)
        } else {
            LoginView()
                .preferredColorScheme(isDarkMode ? .dark: .light)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
