import SwiftUI
import Combine

struct ChallengePhoneView: View {
    @StateObject var viewModel: ChallengePhoneViewModel
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

                        Text("Phone MFA Verified!")
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
                        Text("Phone Verification")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Generate an OTP to be sent to your registered phone number")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        // Generate OTP Button
                        if !viewModel.isOTPGenerated {
                            Button(action: {
                                Task {
                                    await viewModel.generateOTP()
                                }
                            }) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Generate OTP")
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

                        // Error Message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.callout)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // OTP Entry Section (shown after OTP is generated)
                        if viewModel.isOTPGenerated {
                            VStack(spacing: 16) {
                                Text("OTP sent to your phone")
                                    .font(.subheadline)
                                    .foregroundColor(.green)

                                Divider()
                                    .padding(.vertical)

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Enter OTP")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    Text("Enter the 6-digit code sent to your phone")
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
                            }
                        }

                        Spacer()
                    }
                    .padding(.top, 50)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Phone Challenge")
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
