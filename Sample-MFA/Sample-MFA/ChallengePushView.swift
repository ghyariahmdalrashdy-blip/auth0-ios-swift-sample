import SwiftUI
import Combine

struct ChallengePushView: View {
    @StateObject var viewModel: ChallengePushViewModel
    @ObservedObject var loginViewModel: LoginViewModel
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

                        Text("Push MFA Verified!")
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
                        Text("Push Notification Verification")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Generate a push notification challenge and verify it on your device")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        // Generate Challenge Button
                        if !viewModel.isChallengeGenerated {
                            VStack(spacing: 12) {
                                Text("Step 1: Generate Challenge")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)

                                Button(action: {
                                    Task {
                                        await viewModel.generateChallenge()
                                    }
                                }) {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Generate Push Challenge")
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

                        // Error Message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.callout)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Verify Section (shown after challenge is generated)
                        if viewModel.isChallengeGenerated {
                            VStack(spacing: 16) {
                                Text("Push challenge sent!")
                                    .font(.subheadline)
                                    .foregroundColor(.green)

                                Divider()
                                    .padding(.vertical)

                                VStack(spacing: 12) {
                                    Text("Step 2: Verify Challenge")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal)

                                    Text("Check your device for the push notification and approve it, then click verify below")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal)

                                    Button(action: {
                                        Task {
                                            await viewModel.verifyChallenge()
                                        }
                                    }) {
                                        if viewModel.isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Text("Verify Challenge")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(viewModel.isLoading ? Color.gray : Color.green)
                                    .cornerRadius(10)
                                    .disabled(viewModel.isLoading)
                                    .padding(.horizontal)
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding(.top, 50)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Push Challenge")
        .navigationBarTitleDisplayMode(.inline)
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
