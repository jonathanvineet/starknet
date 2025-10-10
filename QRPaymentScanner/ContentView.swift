//
//  ContentView.swift
//  QRPaymentScanner
//
//  Created by Rehaan John on 09/10/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var supabase = SupabaseManager.shared
    
    var body: some View {
        Group {
            if supabase.session != nil {
                HomeView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: supabase.session)
        .onAppear {
            Task {
                await supabase.checkSession()
            }
        }
    }
}
