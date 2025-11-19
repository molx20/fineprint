//
//  breakdownView.swift
//  FinePrint
//
//  View displaying the fine print analysis results
//

import SwiftUI

struct BreakdownView: View {
    let analysis: AnalysisResult

    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Score Cards
                    scoreCardsSection

                    // Offer Summary
                    offerSummarySection

                    // Plain English Summary
                    plainEnglishSection

                    // Hidden Requirements
                    if !analysis.hiddenRequirements.isEmpty {
                        hiddenRequirementsSection
                    }

                    // Red Flags
                    if !analysis.redFlags.isEmpty {
                        redFlagsSection
                    }

                    // Cancellation Difficulty
                    cancellationSection

                    // Action Buttons
                    actionButtonsSection

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color("BackgroundPrimary"))
            .navigationTitle("Truth Breakdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color("TextSecondary"))
                    }
                }
            }
        }
    }

    // MARK: - View Components

    private var scoreCardsSection: some View {
        HStack(spacing: 12) {
            // Risk Score
            ScoreCard(
                title: "Risk Score",
                score: analysis.riskScore,
                color: riskColor(for: analysis.riskScore),
                icon: "exclamationmark.triangle.fill",
                explanation: analysis.riskScoreExplanation
            )

            // Clarity Score
            ScoreCard(
                title: "Clarity",
                score: analysis.clarityScore,
                color: clarityColor(for: analysis.clarityScore),
                icon: "eye.fill",
                explanation: analysis.clarityScoreExplanation
            )
        }
    }

    private var offerSummarySection: some View {
        SectionContainer(icon: "doc.text.fill", title: "What They're Offering", color: Color("PrimaryMain")) {
            Text(analysis.offerSummary)
                .font(.bodyMedium)
                .foregroundColor(Color("TextPrimary"))
        }
    }

    private var plainEnglishSection: some View {
        SectionContainer(icon: "text.bubble.fill", title: "In Plain English", color: Color("PrimaryVariant")) {
            Text(analysis.plainEnglishSummary)
                .font(.bodyMedium)
                .foregroundColor(Color("TextPrimary"))
                .lineSpacing(4)
        }
    }

    private var hiddenRequirementsSection: some View {
        SectionContainer(icon: "eye.slash.fill", title: "Hidden Requirements", color: Color("Warning")) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(analysis.hiddenRequirements.enumerated()), id: \.offset) { index, requirement in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "\(index + 1).circle.fill")
                            .foregroundColor(Color("Warning"))
                            .font(.body)

                        Text(requirement)
                            .font(.bodyMedium)
                            .foregroundColor(Color("TextPrimary"))
                    }

                    if index < analysis.hiddenRequirements.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    private var redFlagsSection: some View {
        SectionContainer(icon: "flag.fill", title: "Red Flags", color: Color("Error")) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(analysis.redFlags.enumerated()), id: \.offset) { index, flag in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.octagon.fill")
                            .foregroundColor(Color("Error"))
                            .font(.body)

                        Text(flag)
                            .font(.bodyMedium)
                            .foregroundColor(Color("TextPrimary"))
                            .fontWeight(.medium)
                    }

                    if index < analysis.redFlags.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    private var cancellationSection: some View {
        SectionContainer(icon: "arrow.uturn.backward.circle.fill", title: "Cancellation", color: Color(analysis.cancellationDifficulty.color)) {
            HStack(spacing: 16) {
                Image(systemName: analysis.cancellationDifficulty.icon)
                    .font(.title)
                    .foregroundColor(Color(analysis.cancellationDifficulty.color))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Difficulty: \(analysis.cancellationDifficulty.rawValue)")
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("TextPrimary"))

                    Text(cancellationDescription)
                        .font(.bodySmall)
                        .foregroundColor(Color("TextSecondary"))
                }

                Spacer()
            }
        }
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Share Button
            Button {
                showingShareSheet = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                    Text("Share Analysis")
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color("PrimaryVariant"))
                .cornerRadius(12)
            }

            // Scan Another Button
            Button {
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                    Text("Scan Another")
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                }
                .foregroundColor(Color("PrimaryMain"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color("PrimaryMain").opacity(0.1))
                .cornerRadius(12)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(text: shareText)
        }
    }

    // MARK: - Helper Properties

    private var cancellationDescription: String {
        switch analysis.cancellationDifficulty {
        case .easy:
            return "Can cancel online/app anytime"
        case .medium:
            return "May require calling or some effort"
        case .hard:
            return "Difficult to cancel, retention tactics"
        }
    }

    private var shareText: String {
        """
        FinePrint Analysis

        Offer: \(analysis.offerSummary)

        Risk Score: \(analysis.riskScore)/100
        Clarity Score: \(analysis.clarityScore)/100
        Cancellation: \(analysis.cancellationDifficulty.rawValue)

        Red Flags:
        \(analysis.redFlags.map { "• \($0)" }.joined(separator: "\n"))

        Analyzed with FinePrint - Reveal the Fine Print
        """
    }

    private func riskColor(for score: Int) -> Color {
        if score < 30 {
            return Color("Success")
        } else if score < 60 {
            return Color("Warning")
        } else {
            return Color("Error")
        }
    }

    private func clarityColor(for score: Int) -> Color {
        if score >= 60 {
            return Color("Success")
        } else if score >= 30 {
            return Color("Warning")
        } else {
            return Color("Error")
        }
    }
}

// MARK: - Score Card Component

struct ScoreCard: View {
    let title: String
    let score: Int
    let color: Color
    let icon: String
    let explanation: String?

    @State private var showingExplanation = false

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text("\(score)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color("TextSecondary"))

            if explanation != nil {
                Button {
                    showingExplanation = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(Color("PrimaryMain"))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color("BackgroundSecondary"))
        .cornerRadius(16)
        .alert("Score Explanation", isPresented: $showingExplanation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(explanation ?? "")
        }
    }
}

// MARK: - Section Container Component

struct SectionContainer<Content: View>: View {
    let icon: String
    let title: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Text(title)
                    .font(.headlineSmall)
                    .foregroundColor(Color("TextPrimary"))
            } icon: {
                Image(systemName: icon)
                    .foregroundColor(color)
            }

            content
        }
        .padding(20)
        .background(Color("BackgroundSecondary"))
        .cornerRadius(16)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Previews

struct BreakdownView_Previews: PreviewProvider {
    static var previews: some View {
        BreakdownView(analysis: sampleAnalysis)
    }

    static var sampleAnalysis: AnalysisResult {
        AnalysisResult(
            offerSummary: "Get 50% off your first 3 months of streaming service",
            plainEnglishSummary: "This offer gives you half off for 3 months, but after that you'll pay full price unless you cancel. You have to sign up with a credit card and it will auto-renew.",
            hiddenRequirements: [
                "Must provide credit card to start trial",
                "Auto-renews at $14.99/month after 3 months",
                "Must cancel at least 2 days before renewal to avoid charges"
            ],
            redFlags: [
                "No reminder before auto-renewal kicks in",
                "Cancellation requires calling customer service"
            ],
            riskScore: 65,
            clarityScore: 45,
            cancellationDifficulty: .hard,
            riskScoreExplanation: "High risk due to auto-renewal without notice and difficult cancellation",
            clarityScoreExplanation: "Terms are somewhat unclear about the renewal process"
        )
    }
}
