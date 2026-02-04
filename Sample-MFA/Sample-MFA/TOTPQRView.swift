import SwiftUI
import Combine

struct TOTPQRView: View {
    @StateObject var viewModel: TOTPQRViewModel
    @ObservedObject var loginViewModel: LoginViewModel
    @State private var otpCode: String = ""
    @State private var isRecoveryCodeCopied = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isEnrolled {
                    // Success State
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)

                        Text("MFA Successfully Enrolled!")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Your account is now protected with two-factor authentication.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: {
                            dismiss()
                        }) {
                            Text("Done")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                    .padding()
                } else {
                    // Setup State
                    VStack(spacing: 20) {
                        Text(viewModel.enrollmentType == .totp ? "Scan QR Code" : "Setup Push Notification")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(viewModel.enrollmentType == .totp
                             ? "Use your authenticator app to scan the QR code below"
                             : "Scan the QR code below to setup push notifications on your device")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        // QR Code Display
                        if let qrImage = viewModel.qrCodeImage {
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 250, height: 250)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(radius: 4)
                        } else if viewModel.isLoading {
                            ProgressView()
                                .frame(width: 250, height: 250)
                        }

                        // Error Message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.callout)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Recovery Code Section
                        if !viewModel.recoveryCode.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Recovery Code")
                                        .font(.headline)

                                    Spacer()

                                    Button(action: {
                                        UIPasteboard.general.string = viewModel.recoveryCode
                                        isRecoveryCodeCopied = true

                                        // Reset the copied state after 2 seconds
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            isRecoveryCodeCopied = false
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: isRecoveryCodeCopied ? "checkmark" : "doc.on.doc")
                                                .font(.system(size: 14))
                                            Text(isRecoveryCodeCopied ? "Copied!" : "Copy")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        }
                                        .foregroundColor(isRecoveryCodeCopied ? .green : .blue)
                                    }
                                }

                                Text("Save this code in a safe place. You can use it to recover your account if you lose access to your authenticator app.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text(viewModel.recoveryCode)
                                    .font(.system(.body, design: .monospaced))
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)

                            Divider()
                                .padding(.vertical)

                            // OTP Entry Section (only for TOTP)
                            if viewModel.enrollmentType == .totp {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Verify Setup")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    Text("Enter the 6-digit code from your authenticator app")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    OTPTextField(otpCode: $otpCode)
                                        .padding(.vertical, 8)
                                }
                                .padding(.horizontal)

                                // Verify Button for TOTP
                                Button(action: {
                                    Task {
                                        await viewModel.verifyOTP(code: otpCode)
                                    }
                                }) {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Verify OTP")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(otpCode.count == 6 && !viewModel.isLoading ? Color.blue : Color.gray)
                                .cornerRadius(10)
                                .disabled(otpCode.count != 6 || viewModel.isLoading)
                                .padding(.horizontal)
                            } else {
                                // Push Notification Verify Section
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Complete Enrollment")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    Text("Tap the button below to complete your push notification enrollment")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.horizontal)

                                // Verify Button for Push
                                Button(action: {
                                    Task {
                                        await viewModel.verifyPush()
                                    }
                                }) {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Complete Enrollment")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(viewModel.isLoading ? Color.gray : Color.blue)
                                .cornerRadius(10)
                                .disabled(viewModel.isLoading)
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(viewModel.enrollmentType == .totp ? "Setup TOTP MFA" : "Setup Push MFA")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .task {
            // Trigger enrollment when view appears
            await viewModel.enroll()
        }
        .onChange(of: viewModel.credentials) {
            // When credentials are received, complete authentication and dismiss
            if let credentials = viewModel.credentials {
                loginViewModel.completeAuthentication(with: credentials)
                // Dismiss after a short delay to show success message
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }
}
