import Auth0
import Foundation
import Combine

@MainActor
final class ChallengePhoneViewModel: ObservableObject {
    let mfaToken: String
    let authenticatorId: String

    @Published var otpCode: String = ""
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isOTPGenerated = false
    @Published var credentials: Credentials?

    private var challenge: MFAChallenge?

    init(mfaToken: String, authenticatorId: String) {
        self.mfaToken = mfaToken
        self.authenticatorId = authenticatorId
    }

    func generateOTP() async {
        isLoading = true
        errorMessage = nil

        do {
            let challenge: MFAChallenge = try await Auth0.mfa()
                .challenge(with: authenticatorId, mfaToken: mfaToken)
                .start()

            self.challenge = challenge
            isLoading = false
            isOTPGenerated = true
            print("OTP generated successfully for phone")
        } catch {
            isLoading = false
            errorMessage = "Failed to generate OTP: \(error.localizedDescription)"
            print("Challenge error: \(error)")
        }
    }

    func verifyOTP() async {
        guard !otpCode.isEmpty, let challenge = challenge else {
            errorMessage = "Please generate OTP first and enter the code"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let credentials = try await Auth0.mfa()
                .verify(oobCode: challenge.oobCode, bindingCode: otpCode, mfaToken: mfaToken)
                .start()

            self.credentials = credentials
            isLoading = false
            print("Phone MFA challenge verified successfully")
            print("Access token: \(credentials.accessToken)")
        } catch {
            isLoading = false
            errorMessage = "Verification failed: \(error.localizedDescription)"
            print("Verification error: \(error)")
        }
    }
}
