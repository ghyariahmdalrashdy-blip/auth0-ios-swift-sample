# Auth0 MFA Sample for iOS

This sample demonstrates how to implement Multi-Factor Authentication (MFA) using Auth0.swift with SwiftUI.

## Features

- Username/Password authentication
- MFA error handling
- List of available MFA factors (enroll or challenge)
- MFA enrollment flow with QR code display
- MFA challenge flow for already enrolled factors
- Support for various MFA types:
  - Authenticator App (OTP)
  - SMS
  - Email
  - Voice
  - Push Notification
  - Security Keys (WebAuthn)

## Setup

### 1. Configure Auth0 Application

1. Create an Auth0 application in your [Auth0 Dashboard](https://manage.auth0.com)
2. Configure your application as a Native application
3. Enable the Database connection (Username-Password-Authentication)
4. Configure MFA settings in your Auth0 Dashboard:
   - Navigate to Security > Multi-factor Auth
   - Enable the MFA factors you want to support

### 2. Update Auth0.plist

Replace the placeholders in `Auth0.plist` with your Auth0 credentials:

```xml
<key>ClientId</key>
<string>YOUR_ACTUAL_CLIENT_ID</string>
<key>Domain</key>
<string>YOUR_ACTUAL_DOMAIN</string>
```

### 3. Configure Callback URLs

Add the following to your Auth0 application settings:

**Allowed Callback URLs:**
```
YOUR_BUNDLE_IDENTIFIER://YOUR_DOMAIN/ios/YOUR_BUNDLE_IDENTIFIER/callback
```

**Allowed Logout URLs:**
```
YOUR_BUNDLE_IDENTIFIER://YOUR_DOMAIN/ios/YOUR_BUNDLE_IDENTIFIER/callback
```

## Project Structure

- **LoginView.swift** - Login screen with username/password fields
- **MFAFactorsView.swift** - Lists available MFA factors (enroll or challenge)
- **MFAEnrollmentView.swift** - Handles MFA enrollment with QR code display
- **MFAChallengeView.swift** - Handles MFA verification for enrolled factors
- **MFAAuthenticator.swift** - Model representing an MFA authenticator
- **ContentView.swift** - Main entry point that displays the LoginView

## Flow

1. User enters username and password in LoginView
2. If MFA is required, the app catches the `mfaRequired` error
3. MFAFactorsView displays available factors
4. User selects a factor:
   - If not enrolled: MFAEnrollmentView shows enrollment steps (QR code for OTP)
   - If already enrolled: MFAChallengeView prompts for verification code
5. After successful verification, user is authenticated

## Testing MFA

### Testing OTP (Authenticator App)

1. Run the app and log in with a test user
2. When prompted, select "Authenticator App (OTP)"
3. Scan the QR code with an authenticator app (Google Authenticator, Authy, etc.)
4. Enter the 6-digit code from your authenticator app
5. On subsequent logins, you'll be prompted for the code directly

### Testing SMS/Email/Voice

1. Run the app and log in with a test user
2. Select SMS, Email, or Voice as your MFA method
3. A code will be sent to your registered phone/email
4. Enter the code to complete authentication

## Auth0.swift PR #1068

This sample is built to work with the MFA support added in [PR #1068](https://github.com/auth0/Auth0.swift/pull/1068) which adds:

- `mfaRequired` error case with `mfaToken` and `authenticators`
- `multifactorEnroll()` method for enrolling in MFA factors
- `multifactorChallenge()` method for initiating MFA challenges
- `multifactorVerify()` method for verifying MFA codes

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Auth0.swift (master branch with MFA support)

## Notes

- The Auth0.swift package is configured to use the master branch to access the MFA features
- Make sure your Auth0 tenant has MFA configured properly
- For production, consider adding error recovery, better UI/UX, and additional security measures
