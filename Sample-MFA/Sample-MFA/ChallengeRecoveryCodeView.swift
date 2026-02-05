import SwiftUI
import Combine

struct ChallengeRecoveryCodeView: View {
    @StateObject var viewModel: ChallengeRecoveryCodeViewModel
    @ObservedObject var loginViewModel: LoginViewModel
    @State private var recoveryCode: String = ""
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

                        Text("Recovery Code Verified!")
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
                        Text("Recovery Code Verification")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Enter the recovery code you saved during enrollment")
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

                        // Recovery Code Entry Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recovery Code")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("Enter the recovery code you saved when setting up MFA")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            TextField("Recovery Code", text: $recoveryCode)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(.body, design: .monospaced))
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding(.vertical, 8)
                        }
                        .padding(.horizontal)

                        // Verify Button
                        Button(action: {
                            Task {
                                await viewModel.verifyRecoveryCode(recoveryCode: recoveryCode)
                            }
                        }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Verify Recovery Code")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(!recoveryCode.isEmpty && !viewModel.isLoading ? Color.blue : Color.gray)
                        .cornerRadius(10)
                        .disabled(recoveryCode.isEmpty || viewModel.isLoading)
                        .padding(.horizontal)

                        Spacer()
                    }
                    .padding(.top, 50)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Recovery Code")
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
