import Auth0
import Foundation
import Combine

@MainActor
final class ChallengeTOTPViewModel: ObservableObject {
    let mfaToken: String

    @Published var otpCode: String = ""
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var credentials: Credentials?

    init(mfaToken: String) {
        self.mfaToken = mfaToken
    }

    func verifyOTP() async {
        guard !otpCode.isEmpty else {
            errorMessage = "Please enter the OTP code"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let credentials = try await Auth0.mfa()
                .verify(otp: otpCode, mfaToken: mfaToken)
                .start()

            self.credentials = credentials
            isLoading = false
            print("TOTP MFA challenge verified successfully")
            print("Access token: \(credentials.accessToken)")
        } catch {
            isLoading = false
            errorMessage = "Verification failed: \(error.localizedDescription)"
            print("Verification error: \(error)")
        }
    }
}
