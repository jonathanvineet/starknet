import SwiftUI

// MARK: - Compilation Test View
public struct CompilationTestView: View {
    // Test if managers are accessible
    @StateObject private var starknetManager = StarknetManager.shared
    @StateObject private var chippiPayManager = ChippiPayManager()
    
    public init() {}
    
    public var body: some View {
        VStack {
            Text("Compilation Test")
            
            // Test StarknetManager
            if starknetManager.isConnected {
                Text("Starknet Connected")
            }
            
            // Test ChippiPayManager
            if chippiPayManager.isAuthenticated {
                Text("ChippiPay Authenticated")
            }
            
            // Test navigation to other views
            NavigationLink("ChippiPay Services") {
                ChippiPayServicesView()
            }
            
            NavigationLink("Vault Actions") {
                VaultActionView(actionType: .deposit)
            }
            
            NavigationLink("Starknet Connect") {
                StarknetConnectView()
            }
        }
        .navigationTitle("Test")
    }
}

#Preview {
    NavigationView {
        CompilationTestView()
    }
}