import SwiftUI
import Combine

struct ChallengeTOTPView: View {
    @StateObject var viewModel: ChallengeTOTPViewModel
    @ObservedObject var loginViewModel: LoginViewModel
    @State private var otpCode: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let credentials = viewModel.credentials {
                    // Success State
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)

                        Text("TOTP MFA Verified!")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("You have successfully verified your identity.")
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
                    // Challenge Flow
                    VStack(spacing: 20) {
                        Text("Authenticator Verification")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Enter the 6-digit code from your authenticator app")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        // Error Message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.callout)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        Divider()
                            .padding(.vertical)

                        // OTP Entry Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Enter OTP")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("Open your authenticator app and enter the code")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            OTPTextField(otpCode: $otpCode)
                                .padding(.vertical, 8)
                        }
                        .padding(.horizontal)

                        // Verify Button
                        Button(action: {
                            Task {
                                await viewModel.verifyOTP()
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

                        Spacer()
                    }
                    .padding(.top, 50)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("TOTP Challenge")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
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
        .onChange(of: otpCode) {
            // Update the view model's otpCode when the binding changes
            viewModel.otpCode = otpCode
        }
    }
}
