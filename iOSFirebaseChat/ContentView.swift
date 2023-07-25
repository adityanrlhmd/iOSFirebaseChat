//
//  ContentView.swift
//  iOSFirebaseChat
//
//  Created by Aditt on 22/07/23.
//

import SwiftUI

class RootModel: ObservableObject {
    @Published var isUserCurrentlyLoggedOut = false

    init() {
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
        }
    }
}

struct ContentView: View {
    @StateObject var vm = RootModel()
    
    var body: some View {
        ZStack {
            if vm.isUserCurrentlyLoggedOut {
                LoginView()
                    .environmentObject(vm)
            } else {
                MainMessagesView()
                    .environmentObject(vm)
            }
        }
        .animation(.default, value: vm.isUserCurrentlyLoggedOut)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(RootModel())
    }
}
