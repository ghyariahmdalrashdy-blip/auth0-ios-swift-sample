import Auth0
import Foundation
import Combine
import UIKit
import CoreImage.CIFilterBuiltins

enum MFAEnrollmentType {
    case totp
    case push
}

@MainActor
final class TOTPQRViewModel: ObservableObject {
    let mfaToken: String
    let enrollmentType: MFAEnrollmentType

    @Published var qrCodeImage: UIImage?
    @Published var recoveryCode: String = ""
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isEnrolled = false
    @Published var credentials: Credentials?

    private var otpChallenge: OTPMFAEnrollmentChallenge?
    private var pushChallenge: PushMFAEnrollmentChallenge?

    init(mfaToken: String, enrollmentType: MFAEnrollmentType = .totp) {
        self.mfaToken = mfaToken
        self.enrollmentType = enrollmentType
    }

    func enroll() async {
        isLoading = true
        errorMessage = nil

        do {
            if enrollmentType == .totp {
                self.otpChallenge = try await Auth0.mfa()
                    .enroll(mfaToken: mfaToken)
                    .start()
                self.recoveryCode = otpChallenge?.recoveryCodes?.first ?? ""
                if let qrImage = generateQRCode(from: otpChallenge?.barcodeUri ?? "") {
                    self.qrCodeImage = qrImage
                } else {
                    self.errorMessage = "Failed to generate QR code"
                }

            } else {
                self.pushChallenge = try await Auth0.mfa()
                    .enroll(mfaToken: mfaToken)
                    .start()
                self.recoveryCode = pushChallenge?.recoveryCodes?.first ?? ""
                if let qrImage = generateQRCode(from: pushChallenge?.barcodeUri ?? "") {
                    self.qrCodeImage = qrImage
                } else {
                    self.errorMessage = "Failed to generate QR code"
                }

            }
        
            // Generate QR code from barcode URI
         
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Enrollment failed: \(error.localizedDescription)"
            print("Enrollment error: \(error)")
        }
    }

    func verifyOTP(code: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Verify the OTP code
            let credentials = try await Auth0.mfa()
                .verify(otp: code, mfaToken: mfaToken)
                .start()

            self.credentials = credentials
            isLoading = false
            isEnrolled = true
            print("MFA enrollment verified successfully")
            print("Access token: \(credentials.accessToken)")
        } catch {
            isLoading = false
            errorMessage = "Verification failed: \(error.localizedDescription)"
            print("Verification error: \(error)")
        }
    }

    func verifyPush() async {
        guard let challenge = pushChallenge else {
            errorMessage = "No enrollment challenge found. Please enroll first."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // For push notifications, we just complete the enrollment without OTP
            let credentials = try await Auth0.mfa()
                .verify(oobCode: challenge.oobCode, bindingCode: nil, mfaToken: mfaToken)
                .start()

            self.credentials = credentials
            isLoading = false
            isEnrolled = true
            print("Push MFA enrollment verified successfully")
            print("Access token: \(credentials.accessToken)")
        } catch {
            isLoading = false
            errorMessage = "Verification failed: \(error.localizedDescription)"
            print("Verification error: \(error)")
        }
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        guard let data = string.data(using: .utf8) else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else { return nil }

        // Scale up the QR code for better quality
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }
}
