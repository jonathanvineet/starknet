

import Foundation
import Supabase

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    @Published var session: Session?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {
        let supabaseURL = URL(string: "https://fsiotcreoonezlwuoydw.supabase.co")!
        let supabaseAnonKey = "sb_publishable_ufk1ypMXqKTTNVIUieAcIw_5jTK5PjL" // Replace with your real key
        
        client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseAnonKey)
        
        Task {
            await checkSession()
        }
    }
    
    // MARK: - Session Management
    
    func checkSession() async {
        do {
            session = try await client.auth.session
        } catch {
            session = nil
            print("No active session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Authentication Methods
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            session = try await client.auth.signIn(
                email: email,
                password: password
            )
        } catch {
            errorMessage = error.localizedDescription
            session = nil
            throw error
        }
    }
    
    /// Sign up and automatically log in the user (no email confirmation needed)
    func signUp(email: String, password: String, username: String, phone: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password,
                data: [
                    "username": .string(username),
                    "phone": .string(phone)
                ]
            )
            
            // Set session immediately - user is logged in after signup
            session = response.session
            
            print("✅ User signed up and logged in successfully")
        } catch {
            errorMessage = error.localizedDescription
            session = nil
            throw error
        }
    }
    
    func signOut() async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            try await client.auth.signOut()
            session = nil
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func resetPassword(email: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            try await client.auth.resetPasswordForEmail(email)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Helper Properties
    
    var isAuthenticated: Bool {
        session != nil
    }
    
    var currentUser: User? {
        session?.user
    }
    
    var userEmail: String? {
        session?.user.email
    }
    
    var userId: UUID? {
        session?.user.id
    }
}
