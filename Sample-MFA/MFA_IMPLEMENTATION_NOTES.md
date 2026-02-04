# MFA Implementation Notes

This sample app demonstrates the UI/UX flow for Multi-Factor Authentication with Auth0.swift. However, PR #1068 which adds the MFA API methods may not be merged to master yet.

## Required Auth0.swift Methods (from PR #1068)

The following methods need to be available in Auth0.swift:

### 1. MFA Error Handling
```swift
case .mfaRequired(let mfaToken, let authenticators)
```
This error case should be returned when MFA is required during login.

### 2. Enrollment
```swift
Auth0
    .authentication()
    .multifactorEnroll(
        mfaToken: String,
        authenticatorType: String
    )
```

### 3. Enrollment Verification
```swift
Auth0
    .authentication()
    .multifactorVerify(
        mfaToken: String,
        otp: String,
        enrollmentId: String
    )
```

### 4. Challenge (for already enrolled factors)
```swift
Auth0
    .authentication()
    .multifactorChallenge(
        mfaToken: String,
        types: [String],
        authenticatorId: String  // Note: parameter name is authenticatorId, not enrollmentId
    )
```

### 5. Challenge Verification
The correct method for verifying a challenge code is TBD. Possible options:
- A separate `verifyChallenge` method
- Reusing `multifactorVerify` with different parameters
- Using the new MFAClient protocol APIs (as mentioned in deprecation warnings)

## Current Status

The views are implemented with:
- ✅ Full UI/UX for login flow
- ✅ MFA factors list display
- ✅ Enrollment flow with QR code display
- ✅ Challenge flow with code entry
- ⚠️ Placeholder API calls (need to be updated once PR #1068 APIs are available)

## To Update the Package Dependency

If PR #1068 is not yet merged, you can point to the PR branch:

1. In Xcode, go to File > Packages > Update to Latest Package Versions
2. Or manually edit `Sample-MFA.xcodeproj/project.pbxproj` to point to the PR branch
3. Or use a specific commit/tag that includes the MFA support

Currently using:
- Repository: https://github.com/auth0/Auth0.swift.git
- Branch: master
- Commit: 6bb9e6ad86a7ca795b18d02ead487132ab770518

## Files That Need API Updates

When the MFA APIs are available, update these files:

1. **LoginView.swift** (line ~105-125)
   - Update `handleLoginError` to properly catch and handle `mfaRequired` error

2. **MFAEnrollmentView.swift** (line ~272-330)
   - Update `startEnrollment()` method
   - Update `verifyEnrollment()` method

3. **MFAChallengeView.swift** (line ~148-204)
   - Update `sendChallenge()` method
   - Update `verifyCode()` method with correct API
   - Update `resendCode()` method

## Testing the App

Until the MFA APIs are available:
1. The login view will work for regular authentication
2. The MFA flow UI can be tested by navigating to the views directly
3. API calls will need to be updated once Auth0.swift MFA support is available

## References

- PR #1068: https://github.com/auth0/Auth0.swift/pull/1068
- Auth0 MFA Documentation: https://auth0.com/docs/secure/multi-factor-authentication
