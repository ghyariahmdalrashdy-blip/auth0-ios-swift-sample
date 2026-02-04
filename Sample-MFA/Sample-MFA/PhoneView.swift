import SwiftUI
import Combine

struct PhoneView: View {
    @StateObject var viewModel: PhoneViewModel
    @ObservedObject var loginViewModel: LoginViewModel
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
                            .padding(.top, 50)

                        Text("MFA Successfully Enrolled!")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Your account is now protected with phone-based two-factor authentication.")
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
                        Text("Setup Phone Authentication")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.top)
                        
                        if !viewModel.isPhoneEnrolled {
                            // Phone Number Entry Section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Enter Phone Number")
                                    .font(.headline)
                                
                                Text("Enter your phone number with country code (e.g., +1234567890)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                TextField("+1234567890", text: $viewModel.phoneNumber)
                                    .keyboardType(.phonePad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.system(.body, design: .default))
                                    .autocapitalization(.none)
                            }
                            .padding(.horizontal)
                            
                            // Enroll Button
                            Button(action: {
                                Task {
                                    await viewModel.enrollPhone()
                                }
                            }) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Text("Send OTP")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding()
                            .background(!viewModel.phoneNumber.isEmpty && !viewModel.isLoading ? Color.blue : Color.gray)
                            .cornerRadius(10)
                            .disabled(viewModel.phoneNumber.isEmpty || viewModel.isLoading)
                            .padding(.horizontal)
                        } else {
                            // Phone Enrolled - Show Verification Section
                            VStack(spacing: 16) {
                                Image(systemName: "message.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.blue)
                                
                                Text("OTP Sent!")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                Text("We've sent a verification code to \(viewModel.phoneNumber)")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            
                            Divider()
                                .padding(.vertical)
                            
                            // OTP Entry Section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Enter Verification Code")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("Enter the 6-digit code sent to your phone")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                OTPTextField(otpCode: $viewModel.otpCode)
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
                            .background(viewModel.otpCode.count == 6 && !viewModel.isLoading ? Color.blue : Color.gray)
                            .cornerRadius(10)
                            .disabled(viewModel.otpCode.count != 6 || viewModel.isLoading)
                            .padding(.horizontal)
                            
                            // Resend OTP Button
                            Button(action: {
                                Task {
                                    await viewModel.enrollPhone()
                                }
                            }) {
                                Text("Resend Code")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            .padding(.top, 8)
                            .disabled(viewModel.isLoading)
                        }
                        
                        // Error Message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.callout)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        Spacer()
                    }
                    .padding(.vertical)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Setup Phone MFA")
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
    }
}
