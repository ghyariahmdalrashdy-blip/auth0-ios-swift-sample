import SwiftUI
import Auth0
import Combine

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        NavigationStack {
                VStack(spacing: 20) {
                    if viewModel.isAuthenticated, let credentials = viewModel.credentials {
                        // Authenticated State - Show Success and Access Token
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.green)
                                .padding(.top, 50)

                            Text("Logged In Successfully!")
                                .font(.title)
                                .fontWeight(.bold)

                            Text("You are now authenticated with MFA")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)

                            Divider()
                                .padding(.vertical)

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Access Token")
                                    .font(.headline)

                                ScrollView(.horizontal, showsIndicators: true) {
                                    Text(credentials.accessToken)
                                        .font(.system(.caption, design: .monospaced))
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                }
                                .frame(maxHeight: 150)

                                    Text("ID Token")
                                        .font(.headline)
                                        .padding(.top, 8)

                                    ScrollView(.horizontal, showsIndicators: true) {
                                        Text(credentials.idToken)
                                            .font(.system(.caption, design: .monospaced))
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                    .frame(maxHeight: 150)

                                if let refreshToken = credentials.refreshToken {
                                    Text("Refresh Token")
                                        .font(.headline)
                                        .padding(.top, 8)

                                    ScrollView(.horizontal, showsIndicators: true) {
                                        Text(refreshToken)
                                            .font(.system(.caption, design: .monospaced))
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                    .frame(maxHeight: 150)
                                }
                            }
                            .padding(.horizontal)

                            Spacer()
                        }
                    } else {
                        // Login Form
                        Text("Login")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.bottom, 30)
                        
                        // Username TextField
                        TextField("Username", text: $viewModel.username)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(.horizontal)
                        
                        // Password SecureField
                        SecureField("Password", text: $viewModel.password)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                        
                        // Login Button
                        Button(action: {
                            Task {
                                await viewModel.login()
                            }
                        }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Login")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .disabled(viewModel.isLoading || viewModel.username.isEmpty || viewModel.password.isEmpty)
                        
                        // Error Message
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        if let challengeAuthenticators = viewModel.challengeAuthenticators {
                            Text("Challenge types")
                                .padding(.bottom, 20)
                            List {
                                ForEach(challengeAuthenticators) { authenticator in
                                    NavigationLink {
                                        if authenticator.type == "phone" || authenticator.type == "sms" {
                                            ChallengePhoneView(
                                                viewModel: ChallengePhoneViewModel(
                                                    mfaToken: viewModel.mfaToken,
                                                    authenticatorId: authenticator.id
                                                ),
                                                loginViewModel: viewModel
                                            )
                                        } else if authenticator.type == "otp" || authenticator.type == "totp" {
                                            ChallengeTOTPView(
                                                viewModel: ChallengeTOTPViewModel(mfaToken: viewModel.mfaToken),
                                                loginViewModel: viewModel
                                            )
                                        } else if authenticator.type == "push-notification" || authenticator.type == "push" {
                                            ChallengePushView(
                                                viewModel: ChallengePushViewModel(
                                                    mfaToken: viewModel.mfaToken,
                                                    authenticatorId: authenticator.id
                                                ),
                                                loginViewModel: viewModel
                                            )
                                        } else {
                                            Text("Challenge for \(authenticator.type) is not yet implemented")
                                                .padding()
                                        }
                                    } label: {
                                        Label {
                                            Text("\(authenticator.id)")
                                        } icon: {
                                            Image(systemName: authenticator.active ? "checkmark.circle.fill" : "checkmark.circle")
                                        }
                                    }
                                }
                            }
                        }
                        
                        if let enrollAuthenticators = viewModel.enrollAuthenticators {
                            Text("Enroll types")
                                .padding(.bottom, 20)
                            List {
                                ForEach(enrollAuthenticators) { factor in
                                    NavigationLink {
                                        if factor == .totp {
                                            TOTPQRView(
                                                viewModel: TOTPQRViewModel(mfaToken: viewModel.mfaToken, enrollmentType: .totp),
                                                loginViewModel: viewModel
                                            )
                                        } else if factor == .sms {
                                            PhoneView(
                                                viewModel: PhoneViewModel(mfaToken: viewModel.mfaToken),
                                                loginViewModel: viewModel
                                            )
                                        } else if factor == .push {
                                            TOTPQRView(
                                                viewModel: TOTPQRViewModel(mfaToken: viewModel.mfaToken, enrollmentType: .push),
                                                loginViewModel: viewModel
                                            )
                                        } else {
                                            Text("Enrollment for \(factor.rawValue) is not yet implemented")
                                                .padding()
                                        }
                                    } label: {
                                        Label {
                                            Text("\(factor.displayName)")
                                        } icon: {
                                            
                                        }

                                    }
                                }
                            }
                        }
                        
                    }
            }.padding(.top, 50)
        }
    }
}

enum Factor: String, Identifiable {
    case recoveryCode = "recovery-code"
    case sms = "phone"
    case push = "push-notification"
    case email = "email"
    case totp = "otp"
    case unkown = ""

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .recoveryCode:
            return "Recovery Code"
        case .sms:
            return "SMS Authentication"
        case .push:
            return "Push Notification"
        case .email:
            return "Email Authentication"
        case .totp:
            return "Authenticator App (TOTP)"
        case .unkown:
            return "Unknown"
        }
    }

    var iconName: String {
        switch self {
        case .recoveryCode:
            return "key.fill"
        case .sms:
            return "message.fill"
        case .push:
            return "bell.fill"
        case .email:
            return "envelope.fill"
        case .totp:
            return "qrcode"
        case .unkown:
            return "questionmark.circle"
        }
    }
}

extension Authenticator: Identifiable {
    
}
