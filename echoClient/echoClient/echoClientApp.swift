//
//  echoClientApp.swift
//  echoClient
//  
//  Created by keeki-fami on 2026/09/30
//  
//

import SwiftUI

@main
struct echoClientApp: App {
    let manager = ClientManager()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(manager)
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .active, .inactive:
                        break
                    case .background:
                        manager.disconnect()
                    @unknown default:
                        break
                    }
                    
                }
        }
    }
}
