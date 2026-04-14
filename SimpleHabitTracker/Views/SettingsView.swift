import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(\.modelContext) private var modelContext
    @State private var showPaywall = false
    @State private var showRestartAlert = false
    @AppStorage("todayIndicatorStyle") private var useDotIndicator = false
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        Form {
            premiumSection
            appearanceSection
            dataSection
            aboutSection
            #if DEBUG
            debugSection
            #endif
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView(purchaseManager: purchaseManager)
        }
        .alert("Restart Required", isPresented: $showRestartAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please restart the app for iCloud Sync changes to take effect.")
        }
    }

    // MARK: - Premium Section

    private var premiumSection: some View {
        Section("Premium") {
            if purchaseManager.isPremium {
                Label("Premium Active", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("Upgrade to Premium", systemImage: "star.circle.fill")
                        .foregroundStyle(.yellow)
                }
            }

            Button {
                Task {
                    await purchaseManager.restorePurchases()
                }
            } label: {
                Label("Restore Purchases", systemImage: "arrow.clockwise")
            }
            .disabled(purchaseManager.isLoading)
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        Section("Appearance") {
            Toggle(isOn: $useDotIndicator) {
                Label("Dot Today Indicator", systemImage: "circle.fill")
            }

            HStack {
                Label("Themes", systemImage: "paintbrush")
                Spacer()
                if !purchaseManager.isPremium {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(purchaseManager.isPremium ? .primary : .secondary)
            .onTapGesture {
                if !purchaseManager.isPremium {
                    showPaywall = true
                }
            }
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        Section("Data") {
            if purchaseManager.isPremium {
                Toggle(isOn: Binding(
                    get: { iCloudSyncEnabled },
                    set: { newValue in
                        iCloudSyncEnabled = newValue
                        showRestartAlert = true
                    }
                )) {
                    Label("iCloud Sync", systemImage: "icloud")
                }
            } else {
                HStack {
                    Label("iCloud Sync", systemImage: "icloud")
                    Spacer()
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.secondary)
                .onTapGesture {
                    showPaywall = true
                }
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }

            if let url = URL(string: "https://example.com/privacy-policy") {
                Link(destination: url) {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Debug Section

    #if DEBUG
    private var debugSection: some View {
        Section("Debug") {
            Button {
                purchaseManager.debugTogglePremium()
            } label: {
                Label(
                    purchaseManager.isPremium ? "Disable Premium" : "Enable Premium",
                    systemImage: "ladybug"
                )
            }

            Button {
                UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
            } label: {
                Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
            }

            Button(role: .destructive) {
                clearAllData()
            } label: {
                Label("Clear All Data", systemImage: "trash")
                    .foregroundStyle(.red)
            }
        }
    }

    private func clearAllData() {
        do {
            try modelContext.delete(model: Habit.self)
            try modelContext.save()
        } catch {
            print("Failed to clear all data: \(error)")
        }
    }
    #endif
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(PurchaseManager())
    .modelContainer(for: Habit.self, inMemory: true)
}
