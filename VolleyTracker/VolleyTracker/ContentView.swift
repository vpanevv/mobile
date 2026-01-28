import SwiftUI // import the SwiftUI framework

struct ContentView: View { // Define the ContentView struct conforming to the View protocol
    // every view must be struct and implement VIEW
    var body: some View { // how the view is composed
        NavigationStack { // modern navigation in SwiftUI (iOS 16+)
            WelcomeView() // the first screen

        }
    }
}

#Preview {
    ContentView()
    //App → ContentView → WelcomeView → CreateCoachView → ...
}

//🧠 Каква е ролята на ContentView в приложението?
//
//Много важно обобщение:

//    •    VolleyTrackerApp.swift казва:

//“Когато стартира app-а → покажи ContentView”

//    •    ContentView казва:

//“Имам NavigationStack и първият екран е WelcomeView”

//    •    WelcomeView е реалният първи UX екран
