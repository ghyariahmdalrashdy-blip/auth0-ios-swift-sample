import Auth0
import Foundation
import Combine

@MainActor
final class ChallengeRecoveryCodeViewModel: ObservableObject {

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var credentials: Credentials?

    let mfaToken: String

    init(mfaToken: String) {
        self.mfaToken = mfaToken
    }

    func verifyRecoveryCode(recoveryCode: String) async {
        guard !recoveryCode.isEmpty else {
            errorMessage = "Please enter a recovery code"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Recovery codes are verified using the same API as OTP codes
            let credentials = try await Auth0
                .mfa()
                .verify(otp: recoveryCode, mfaToken: mfaToken)
                .start()

            isLoading = false
            self.credentials = credentials
        } catch {
            isLoading = false
            errorMessage = "Failed to verify recovery code: \(error.localizedDescription)"
            print("Recovery code verification error: \(error)")
        }
    }
}
