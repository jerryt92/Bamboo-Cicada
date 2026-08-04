//
//  Bamboo_CicadaApp.swift
//  Bamboo Cicada
//
//  Created by Tian Jingli on 2026/8/4.
//

import SwiftUI

@main
struct Bamboo_CicadaApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(red: 0.08, green: 0.25, blue: 0.17)
                    .ignoresSafeArea(.all)
                GestureProtectedView {
                    ContentView()
                }
                .ignoresSafeArea(.all)
            }
            .background(Color(red: 0.08, green: 0.25, blue: 0.17))
            .ignoresSafeArea(.all)
        }
    }
}
