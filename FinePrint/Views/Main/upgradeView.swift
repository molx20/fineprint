//
//  upgradeView.swift
//  FinePrint
//
//  View showing free vs paid tier comparison and upgrade option
//

import SwiftUI

struct UpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var scanManager = ScanManager.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerSection

                    // Comparison Cards
                    comparisonSection

                    // Features List
                    featuresSection

                    // Upgrade Button
                    upgradeButton

                    // Disclaimer
                    disclaimerSection

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color("BackgroundPrimary"))
            .navigationTitle("Upgrade to Pro")
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

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(Color("PrimaryMain"))

            Text("Unlimited Truth")
                .font(.titleLarge)
                .foregroundColor(Color("TextPrimary"))

            Text("Scan as many offers as you want, whenever you want")
                .font(.bodyMedium)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    private var comparisonSection: some View {
        HStack(spacing: 12) {
            // Free Plan Card
            PlanCard(
                title: "Free",
                price: "$0",
                period: "forever",
                scans: "1 scan/day",
                highlight: false
            )

            // Pro Plan Card
            PlanCard(
                title: "Pro",
                price: "$4.99",
                period: "per month",
                scans: "Unlimited scans",
                highlight: true
            )
        }
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pro Features")
                .font(.headlineSmall)
                .foregroundColor(Color("TextPrimary"))

            VStack(spacing: 12) {
                FeatureRow(
                    icon: "infinity",
                    title: "Unlimited Scans",
                    description: "Analyze as many offers as you need",
                    isPro: true
                )

                FeatureRow(
                    icon: "bolt.fill",
                    title: "Priority Processing",
                    description: "Faster analysis with priority queue",
                    isPro: true
                )

                FeatureRow(
                    icon: "clock.fill",
                    title: "Scan History",
                    description: "Access all your past scans anytime",
                    isPro: true
                )

                FeatureRow(
                    icon: "bell.fill",
                    title: "Smart Alerts",
                    description: "Get notified of sketchy deals (coming soon)",
                    isPro: true
                )

                FeatureRow(
                    icon: "heart.fill",
                    title: "Support Development",
                    description: "Help us build more consumer protection features",
                    isPro: true
                )
            }
        }
        .padding(20)
        .background(Color("BackgroundSecondary"))
        .cornerRadius(16)
    }

    private var upgradeButton: some View {
        Button {
            // TODO: Integrate actual payment processing
            // For now, this is a placeholder
            showUpgradePlaceholder()
        } label: {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.title3)
                Text("Upgrade to Pro")
                    .font(.bodyLarge)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [Color("PrimaryMain"), Color("PrimaryVariant")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color("PrimaryMain").opacity(0.3), radius: 10, y: 5)
        }
    }

    private var disclaimerSection: some View {
        VStack(spacing: 12) {
            Text("Payment integration coming soon")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color("TextSecondary"))

            Text("• Cancel anytime, no questions asked\n• 7-day money-back guarantee\n• Secure payment via App Store")
                .font(.caption)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Actions

    private func showUpgradePlaceholder() {
        #if DEBUG
        // For testing: toggle paid status
        scanManager.togglePaidStatus()
        dismiss()
        #else
        // TODO: Implement actual payment flow (StoreKit, Stripe, etc.)
        // For now, just dismiss
        dismiss()
        #endif
    }
}

// MARK: - Plan Card Component

struct PlanCard: View {
    let title: String
    let price: String
    let period: String
    let scans: String
    let highlight: Bool

    var body: some View {
        VStack(spacing: 16) {
            if highlight {
                Text("BEST VALUE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color("PrimaryMain"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color("PrimaryMain").opacity(0.1))
                    .cornerRadius(8)
            } else {
                Spacer()
                    .frame(height: 24)
            }

            Text(title)
                .font(.headlineSmall)
                .foregroundColor(Color("TextPrimary"))

            VStack(spacing: 4) {
                Text(price)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color("TextPrimary"))

                Text(period)
                    .font(.caption)
                    .foregroundColor(Color("TextSecondary"))
            }

            Text(scans)
                .font(.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(highlight ? Color("PrimaryMain") : Color("TextSecondary"))

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(highlight ? Color("PrimaryMain").opacity(0.05) : Color("BackgroundSecondary"))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(highlight ? Color("PrimaryMain") : Color.clear, lineWidth: 2)
        )
        .cornerRadius(16)
    }
}

// MARK: - Feature Row Component

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let isPro: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isPro ? Color("PrimaryMain") : Color("TextSecondary"))
                .frame(width: 32, height: 32)
                .background(isPro ? Color("PrimaryMain").opacity(0.1) : Color.clear)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("TextPrimary"))

                Text(description)
                    .font(.bodySmall)
                    .foregroundColor(Color("TextSecondary"))
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Previews

struct UpgradeView_Previews: PreviewProvider {
    static var previews: some View {
        UpgradeView()
    }
}
