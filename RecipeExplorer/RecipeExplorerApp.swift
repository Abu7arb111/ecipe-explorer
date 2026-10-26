import SwiftUI

@main struct RecipeExplorerApp: App {
    @StateObject private var store = RecipeStore()
    var body: some Scene {
        WindowGroup { ContentView().environmentObject(store) }
    }
}
