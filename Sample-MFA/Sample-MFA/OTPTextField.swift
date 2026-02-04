import SwiftUI

struct OTPTextField: View {
    @Binding var otpCode: String
    @FocusState private var focusedField: Int?

    private let fieldCount = 6

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<fieldCount, id: \.self) { index in
                OTPDigitField(
                    digit: binding(for: index),
                    isFocused: focusedField == index
                )
                .focused($focusedField, equals: index)
            }
        }
        .onAppear {
            // Auto-focus first field when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = 0
            }
        }
    }

    private func binding(for index: Int) -> Binding<String> {
        Binding<String>(
            get: {
                guard index < otpCode.count else { return "" }
                let char = Array(otpCode)[index]
                return String(char)
            },
            set: { newValue in
                // Filter to only digits
                let filtered = newValue.filter { $0.isNumber }

                if filtered.isEmpty {
                    // Handle deletion
                    if index < otpCode.count {
                        var chars = Array(otpCode)
                        chars.remove(at: index)
                        otpCode = String(chars)

                        // Move to previous field
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            if index > 0 {
                                focusedField = index - 1
                            }
                        }
                    }
                } else if filtered.count == 1 {
                    // Handle single digit
                    var chars = Array(otpCode)

                    // Ensure array is large enough
                    while chars.count < index {
                        chars.append(" ")
                    }

                    if index < chars.count {
                        chars[index] = filtered.first!
                    } else {
                        chars.append(filtered.first!)
                    }

                    otpCode = String(chars)

                    // Move to next field
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        if index < fieldCount - 1 && otpCode.count > index {
                            focusedField = index + 1
                        } else {
                            focusedField = nil
                        }
                    }
                } else {
                    // Handle paste - multiple digits
                    let digits = String(filtered.prefix(fieldCount))
                    otpCode = digits

                    // Focus appropriate field
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        focusedField = min(digits.count, fieldCount - 1)
                    }
                }
            }
        )
    }
}

struct OTPDigitField: View {
    @Binding var digit: String
    let isFocused: Bool

    var body: some View {
        TextField("", text: $digit)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.system(.title, design: .monospaced))
            .fontWeight(.semibold)
            .frame(width: 45, height: 55)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
            )
    }
}
