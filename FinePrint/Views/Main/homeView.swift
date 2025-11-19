//
//  homeView.swift
//  FinePrint
//
//  Main home screen with scan options
//

import SwiftUI

struct HomeView: View {
    @StateObject private var scanManager = ScanManager.shared
    @State private var scanInputType: ScanInputType?
    @State private var showingUpgrade = false

    var body: some View {
        NavigationView {
            ZStack {
                Color("BackgroundPrimary")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection

                        // Scan Count Status
                        scanStatusCard

                        // Primary Actions
                        scanActionsSection

                        // Recent Scans (if any)
                        if !scanManager.scanHistory.isEmpty {
                            recentScansSection
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("FinePrint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if !scanManager.isPaid {
                            Button {
                                showingUpgrade = true
                            } label: {
                                Label("Upgrade to Pro", systemImage: "star.fill")
                            }
                        }

                        #if DEBUG
                        Divider()
                        Button("Toggle Paid Status") {
                            scanManager.togglePaidStatus()
                        }
                        Button("Simulate Used Scan") {
                            scanManager.simulateUsedScan()
                        }
                        Button("Reset Scan Count") {
                            scanManager.resetScanCount()
                        }
                        #endif
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
            }
            .sheet(item: $scanInputType) { inputType in
                ScanInputView(inputType: inputType)
            }
            .sheet(isPresented: $showingUpgrade) {
                UpgradeView()
            }
            .sheet(item: $scanManager.currentAnalysis) { analysis in
                BreakdownView(analysis: analysis)
            }
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(Color("PrimaryMain"))

            Text("Reveal the Fine Print")
                .font(.titleLarge)
                .foregroundColor(Color("TextPrimary"))

            Text("Understand what you're really signing up for")
                .font(.bodyMedium)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    private var scanStatusCard: some View {
        HStack(spacing: 16) {
            Image(systemName: scanManager.isPaid ? "infinity" : "checkmark.circle.fill")
                .font(.title)
                .foregroundColor(Color("PrimaryMain"))

            VStack(alignment: .leading, spacing: 4) {
                if scanManager.isPaid {
                    Text("Pro Member")
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("TextPrimary"))

                    Text("Unlimited scans")
                        .font(.bodySmall)
                        .foregroundColor(Color("TextSecondary"))
                } else {
                    Text("Free Plan")
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("TextPrimary"))

                    if scanManager.canScanToday {
                        Text("\(scanManager.scansRemainingToday) scan\(scanManager.scansRemainingToday == 1 ? "" : "s") left today")
                            .font(.bodySmall)
                            .foregroundColor(Color("Success"))
                    } else {
                        Text("No scans remaining today")
                            .font(.bodySmall)
                            .foregroundColor(Color("Error"))
                    }
                }
            }

            Spacer()

            if !scanManager.isPaid {
                Button {
                    showingUpgrade = true
                } label: {
                    Text("Upgrade")
                        .font(.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("PrimaryMain"))
                }
            }
        }
        .padding(20)
        .background(Color("BackgroundSecondary"))
        .cornerRadius(16)
    }

    private var scanActionsSection: some View {
        VStack(spacing: 16) {
            Text("Paste URL for Offer/Promo")
                .font(.headlineSmall)
                .foregroundColor(Color("TextPrimary"))
                .frame(maxWidth: .infinity, alignment: .leading)

            // URL Button
            Button {
                scanInputType = .url
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "link.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color("PrimaryMain"))
                        .frame(width: 50, height: 50)
                        .background(Color("PrimaryMain").opacity(0.1))
                        .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enter URL")
                            .font(.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("TextPrimary"))

                        Text("Paste a link to analyze an offer or promotion")
                            .font(.bodySmall)
                            .foregroundColor(Color("TextSecondary"))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(Color("TextSecondary"))
                }
                .padding(20)
                .background(Color("BackgroundSecondary"))
                .cornerRadius(16)
            }
            .disabled(!scanManager.canScanToday)
            .opacity(scanManager.canScanToday ? 1.0 : 0.5)

            if !scanManager.canScanToday {
                Text("You've reached your daily limit. Upgrade for unlimited scans.")
                    .font(.bodySmall)
                    .foregroundColor(Color("Error"))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
    }

    private var recentScansSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recent Scans")
                    .font(.headlineSmall)
                    .foregroundColor(Color("TextPrimary"))

                Spacer()

                Button("Clear") {
                    scanManager.clearHistory()
                }
                .font(.bodySmall)
                .foregroundColor(Color("PrimaryMain"))
            }

            VStack(spacing: 12) {
                ForEach(scanManager.scanHistory.prefix(5)) { item in
                    Button {
                        scanManager.currentAnalysis = item.analysis
                    } label: {
                        recentScanRow(item)
                    }
                }
            }
        }
    }

    private func recentScanRow(_ item: ScanHistoryItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.sourceType.icon)
                .font(.title3)
                .foregroundColor(Color("PrimaryMain"))
                .frame(width: 40, height: 40)
                .background(Color("PrimaryMain").opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.analysis.offerSummary)
                    .font(.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(Color("TextPrimary"))
                    .lineLimit(2)

                Text(item.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(Color("TextSecondary"))
            }

            Spacer()

            // Risk indicator
            Circle()
                .fill(riskColor(for: item.analysis.riskScore))
                .frame(width: 12, height: 12)
        }
        .padding(12)
        .background(Color("BackgroundSecondary"))
        .cornerRadius(12)
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
}

// MARK: - Scan Input Type

enum ScanInputType: Identifiable {
    case url

    var id: String {
        return "url"
    }
}

// MARK: - Previews

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
