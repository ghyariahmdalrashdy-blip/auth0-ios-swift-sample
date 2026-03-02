import Combine
import Auth0
import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showMFAFactors = false
    @Published var isAuthenticated = false
    @Published var credentials: Credentials?
    private(set) var mfaToken: String = ""
    @Published var challengeAuthenticators: [Authenticator]? = nil
    @Published var enrollAuthenticators: [Factor]? = nil

    func login() async {
        isLoading = true
        errorMessage = nil
        do {
            let credentials = try await Auth0
                .authentication()
                .login(usernameOrEmail: username,
                       password: password,
                       realmOrConnection: "Username-Password-Authentication",
                       scope: "openid profile offline_access")
                .start()
            isLoading = false

            // Successfully authenticated
            self.credentials = credentials
            print("Login successful: \(credentials)")
            isAuthenticated = true
        } catch {
            isLoading = false
            do {
                try await handleLoginError(error)
            } catch {
                print("error: \(error)")
            }
        }
    }

    private func handleLoginError(_ error: Error) async throws {
        // Check if it's an MFA required error
        if let authError = error as? AuthenticationError,
           authError.isMultifactorRequired,
            let payload = authError.mfaRequiredErrorPayload {
            mfaToken = payload.mfaToken
            showMFAFactors = true
            if let challengeTypes = authError.mfaRequiredErrorPayload?.mfaRequirements.challenge {
                self.challengeAuthenticators = try await Auth0.mfa()
                    .getAuthenticators(mfaToken: payload.mfaToken, factorsAllowed: challengeTypes.map { $0.type })
                    .start()
            }

            if let enrollTypes = authError.mfaRequiredErrorPayload?.mfaRequirements.enroll {
                self.enrollAuthenticators = enrollTypes.map { Factor(rawValue: $0.type) ?? .unkown }
            }
        } else {
            self.errorMessage = error.localizedDescription
        }
    }

    func completeAuthentication(with credentials: Credentials) {
        self.credentials = credentials
        self.isAuthenticated = true
        self.showMFAFactors = false
        self.challengeAuthenticators = nil
        self.enrollAuthenticators = nil
        print("Authentication completed with access token: \(credentials.accessToken)")
    }
}
