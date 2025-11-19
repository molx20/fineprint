//
//  scanInputView.swift
//  FinePrint
//
//  View for inputting URL to analyze
//

import SwiftUI

struct ScanInputView: View {
    let inputType: ScanInputType

    @Environment(\.dismiss) private var dismiss
    @StateObject private var scanManager = ScanManager.shared

    // URL Input State
    @State private var urlText: String = ""
    @State private var isValidURL: Bool = false

    // Loading State
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var showingError = false

    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Input Method Icon
                    inputIcon

                    // URL Input Section
                    urlInputSection

                    // Analyze Button
                    analyzeButton

                    // Info Section
                    infoSection

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationTitle("Enter URL")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .disabled(isAnalyzing)
        .overlay {
            if isAnalyzing {
                loadingOverlay
            }
        }
    }

    // MARK: - View Components

    private var inputIcon: some View {
        Image(systemName: "link.circle.fill")
            .font(.system(size: 60))
            .foregroundColor(Color("PrimaryMain"))
            .padding(.top, 20)
    }

    private var urlInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Promotional URL")
                .font(.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(Color("TextPrimary"))

            TextField("https://example.com/promo", text: $urlText)
                .textFieldStyle(.plain)
                .font(.bodyMedium)
                .padding(16)
                .background(Color("BackgroundSecondary"))
                .cornerRadius(12)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .autocorrectionDisabled()
                .onChange(of: urlText) { newValue in
                    validateURL(newValue)
                }

            if !urlText.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: isValidURL ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(isValidURL ? Color("Success") : Color("Warning"))
                    Text(isValidURL ? "Valid URL" : "Please enter a valid URL")
                        .font(.caption)
                        .foregroundColor(isValidURL ? Color("Success") : Color("Warning"))
                }
            }

            Text("Paste the link to a promotional offer, subscription, or special deal")
                .font(.bodySmall)
                .foregroundColor(Color("TextSecondary"))
        }
    }

    private var analyzeButton: some View {
        Button {
            analyzeInput()
        } label: {
            HStack {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.title3)
                Text("Analyze Fine Print")
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isValidURL ? Color("PrimaryMain") : Color.gray)
            .cornerRadius(12)
        }
        .disabled(!isValidURL || isAnalyzing)
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("What we'll analyze")
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("TextPrimary"))
            } icon: {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Color("PrimaryMain"))
            }

            VStack(alignment: .leading, spacing: 8) {
                infoItem(icon: "text.magnifyingglass", text: "Extract and read all fine print")
                infoItem(icon: "globe", text: "Scrape related terms & conditions")
                infoItem(icon: "exclamationmark.triangle.fill", text: "Identify hidden requirements")
                infoItem(icon: "flag.fill", text: "Highlight red flags")
                infoItem(icon: "chart.bar.fill", text: "Calculate risk and clarity scores")
            }
        }
        .padding(20)
        .background(Color("BackgroundSecondary"))
        .cornerRadius(12)
    }

    private func infoItem(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Color("PrimaryVariant"))
                .frame(width: 20)
            Text(text)
                .font(.bodySmall)
                .foregroundColor(Color("TextSecondary"))
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(Color("PrimaryMain"))

                Text("Reading the fine print...")
                    .font(.bodyLarge)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text("This may take 10-30 seconds")
                    .font(.bodySmall)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(32)
            .background(Color("BackgroundSecondary"))
            .cornerRadius(20)
        }
    }

    // MARK: - Actions

    private func validateURL(_ text: String) {
        if text.isEmpty {
            isValidURL = false
            return
        }

        // Add https:// if missing
        var urlString = text
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "https://\(urlString)"
        }

        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            isValidURL = true
        } else {
            isValidURL = false
        }
    }

    private func analyzeInput() {
        isAnalyzing = true
        errorMessage = nil

        Task {
            do {
                var urlString = urlText
                if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
                    urlString = "https://\(urlString)"
                }
                _ = try await scanManager.analyzeURL(urlString)

                // Success - dismiss and show results
                await MainActor.run {
                    isAnalyzing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Previews

struct ScanInputView_Previews: PreviewProvider {
    static var previews: some View {
        ScanInputView(inputType: .url)
    }
}
