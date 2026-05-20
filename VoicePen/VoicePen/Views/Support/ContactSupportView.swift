import SwiftUI

struct ContactSupportView: View {
    @State private var selectedSubject: SupportSubject = .general
    @State private var customSubject = ""
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    private let feedbackURL = "https://feedback-board.iocompile67692.workers.dev/api/feedback"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                subjectSection
                if selectedSubject == .other {
                    customSubjectField
                }
                nameField
                emailField
                messageField
                submitButton
            }
            .padding()
        }
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Thank You!", isPresented: $showSuccess) {
            Button("OK") { }
        } message: {
            Text("Your feedback has been submitted. We'll get back to you soon.")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var subjectSection: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                .autocorrectionDisabled()
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
            if isSubmitting {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                Text("Submit")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .background(Color.accentColor)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .disabled(isSubmitting || name.isEmpty || email.isEmpty || message.isEmpty)
        .opacity(name.isEmpty || email.isEmpty || message.isEmpty ? 0.5 : 1.0)
    }

    private func submitFeedback() {
        isSubmitting = true
        errorMessage = nil

        let subjectText = selectedSubject == .other ? customSubject : selectedSubject.displayName

        let body: [String: String] = [
            "name": name,
            "email": email,
            "subject": subjectText,
            "message": message,
            "app_name": "VoicePen"
        ]

        guard let url = URL(string: feedbackURL),
              let httpBody = try? JSONEncoder().encode(body) else {
            isSubmitting = false
            errorMessage = "Failed to prepare request."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody

        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    showSuccess = true
                    name = ""
                    email = ""
                    message = ""
                    customSubject = ""
                    selectedSubject = .general
                } else {
                    errorMessage = "Failed to submit feedback. Please try again."
                }
            }
        }.resume()
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
        case .featureSuggestion: return "Feature Suggestion"
        case .bugReport: return "Bug Report"
        case .usageQuestion: return "Usage Question"
        case .performanceIssue: return "Performance"
        case .uiImprovement: return "UI Improvement"
        case .other: return "Other"
        }
    }
}

#Preview {
    NavigationStack {
        ContactSupportView()
    }
}
