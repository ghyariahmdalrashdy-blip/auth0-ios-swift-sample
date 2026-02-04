import Auth0
import Foundation
import Combine

@MainActor
final class PhoneViewModel: ObservableObject {
    let mfaToken: String

    @Published var phoneNumber: String = ""
    @Published var otpCode: String = ""
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isEnrolled = false
    @Published var isPhoneEnrolled = false
    @Published var credentials: Credentials?

    private var challenge: MFAEnrollmentChallenge?

    init(mfaToken: String) {
        self.mfaToken = mfaToken
    }

    func enrollPhone() async {
        guard !phoneNumber.isEmpty else {
            errorMessage = "Please enter a phone number"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let challenge: MFAEnrollmentChallenge = try await Auth0.mfa()
                .enroll(mfaToken: mfaToken, phoneNumber: phoneNumber)
                .start()

            self.challenge = challenge
            isLoading = false
            isPhoneEnrolled = true
            print("Phone enrollment initiated successfully")
            print("OTP sent to: \(phoneNumber)")
        } catch {
            isLoading = false
            errorMessage = "Enrollment failed: \(error.localizedDescription)"
            print("Phone enrollment error: \(error)")
        }
    }

    func verifyOTP() async {
        guard !otpCode.isEmpty, let challenge else {
            errorMessage = "Please enter the OTP code"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Verify the OTP code
            let credentials = try await Auth0.mfa()
                .verify(oobCode: challenge.oobCode, bindingCode: otpCode, mfaToken: mfaToken)
                .start()

            self.credentials = credentials
            isLoading = false
            isEnrolled = true
            print("Phone MFA enrollment verified successfully")
            print("Access token: \(credentials.accessToken)")
        } catch {
            isLoading = false
            errorMessage = "Verification failed: \(error.localizedDescription)"
            print("Verification error: \(error)")
        }
    }
}
