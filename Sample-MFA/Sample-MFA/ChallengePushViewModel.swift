import Auth0
import Foundation
import Combine

@MainActor
final class ChallengePushViewModel: ObservableObject {
    let mfaToken: String
    let authenticatorId: String

    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isChallengeGenerated = false
    @Published var credentials: Credentials?

    private var challenge: MFAChallenge?

    init(mfaToken: String, authenticatorId: String) {
        self.mfaToken = mfaToken
        self.authenticatorId = authenticatorId
    }

    func generateChallenge() async {
        isLoading = true
        errorMessage = nil

        do {
            let challenge: MFAChallenge = try await Auth0.mfa()
                .challenge(with: authenticatorId, mfaToken: mfaToken)
                .start()

            self.challenge = challenge
            isLoading = false
            isChallengeGenerated = true
            print("Push challenge generated successfully")
        } catch {
            isLoading = false
            errorMessage = "Failed to generate challenge: \(error.localizedDescription)"
            print("Challenge error: \(error)")
        }
    }

    func verifyChallenge() async {
        guard let challenge = challenge else {
            errorMessage = "Please generate a challenge first"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let credentials = try await Auth0.mfa()
                .verify(oobCode: challenge.oobCode, bindingCode: nil, mfaToken: mfaToken)
                .start()

            self.credentials = credentials
            isLoading = false
            print("Push MFA challenge verified successfully")
            print("Access token: \(credentials.accessToken)")
        } catch {
            isLoading = false
            errorMessage = "Verification failed: \(error.localizedDescription)"
            print("Verification error: \(error)")
        }
    }
}
