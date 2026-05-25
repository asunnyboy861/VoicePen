import SwiftUI

struct FeedbackRequest: Codable {
    let name: String
    let email: String
    let subject: String
    let message: String
    let app_name: String
}

struct FeedbackResponse: Codable {
    let success: Bool
    let id: Int?
    let error: String?
}

struct ContactSupportView: View {
    @State private var selectedSubject: SupportSubject = .general
    @State private var customSubject = ""
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var isSubmitting = false
    @State private var showResultAlert = false
    @State private var resultSuccess = false
    @State private var resultMessage = ""

    private let backendURL = "https://feedback-board.iocompile67692.workers.dev/api/feedback"
    private let appName = "VoicePen"

    private var isFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        !message.isEmpty &&
        (selectedSubject != .other || !customSubject.isEmpty)
    }

    private var emailSubject: String {
        selectedSubject == .other ? customSubject : selectedSubject.displayName
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                subjectSection
                if selectedSubject == .other {
                    customSubjectField
                }
                nameField
                emailField
                messageField
                submitButton
                privacyNote
            }
            .padding()
        }
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Support", isPresented: $showResultAlert) {
            Button("OK") {
                if resultSuccess {
                    resetForm()
                }
            }
        } message: {
            Text(resultMessage)
        }
    }

    private var subjectSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Subject")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(SupportSubject.allCases, id: \.self) { subject in
                    Button(action: { selectedSubject = subject }) {
                        Text(subject.displayName)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(selectedSubject == subject ? Color.accentColor : Color(.secondarySystemBackground))
                            .foregroundStyle(selectedSubject == subject ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .accessibilityLabel(subject.displayName)
                }
            }
        }
    }

    private var customSubjectField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Custom Subject")
                .font(.headline)
            TextField("Enter your subject", text: $customSubject)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Name")
                .font(.headline)
            TextField("Your name", text: $name)
                .textFieldStyle(.roundedBorder)
                .textContentType(.name)
        }
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Email")
                .font(.headline)
            TextField("your@email.com", text: $email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
        }
    }

    private var messageField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Message")
                .font(.headline)
            TextEditor(text: $message)
                .frame(minHeight: 120)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var submitButton: some View {
        Button(action: submitFeedback) {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                }
                Text(isSubmitting ? "Sending..." : "Submit")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid ? Color.accentColor : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!isFormValid || isSubmitting)
    }

    private var privacyNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(.green)
            Text("Your feedback helps us improve VoicePen. We only collect the information you provide above.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func submitFeedback() {
        guard isFormValid else { return }
        isSubmitting = true

        let request = FeedbackRequest(
            name: name,
            email: email,
            subject: emailSubject,
            message: message,
            app_name: appName
        )

        guard let url = URL(string: backendURL) else {
            showResult(success: false, message: "Invalid backend URL.")
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            showResult(success: false, message: "Failed to encode request.")
            return
        }

        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                isSubmitting = false

                if let error = error {
                    showResult(success: false, message: "Network error: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    showResult(success: false, message: "No response from server.")
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(FeedbackResponse.self, from: data)
                    if decoded.success {
                        showResult(success: true, message: "Thank you! Your feedback has been received.")
                    } else {
                        showResult(success: false, message: decoded.error ?? "Something went wrong. Please try again.")
                    }
                } catch {
                    showResult(success: false, message: "Failed to parse server response.")
                }
            }
        }.resume()
    }

    private func showResult(success: Bool, message: String) {
        resultSuccess = success
        resultMessage = message
        showResultAlert = true
    }

    private func resetForm() {
        name = ""
        email = ""
        message = ""
        customSubject = ""
        selectedSubject = .general
    }
}

enum SupportSubject: String, CaseIterable {
    case general
    case featureSuggestion
    case bugReport
    case usageQuestion
    case performanceIssue
    case uiImprovement
    case other

    var displayName: String {
        switch self {
        case .general: return "General"
        case .featureSuggestion: return "Feature"
        case .bugReport: return "Bug Report"
        case .usageQuestion: return "Question"
        case .performanceIssue: return "Performance"
        case .uiImprovement: return "UI"
        case .other: return "Other"
        }
    }
}

#Preview {
    NavigationStack {
        ContactSupportView()
    }
}
