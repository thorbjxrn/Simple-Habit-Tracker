import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    var purchaseManager: PurchaseManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Header
                    headerSection

                    // MARK: - Benefits
                    benefitsSection

                    // MARK: - Price & Purchase
                    purchaseSection

                    // MARK: - Restore
                    restoreSection
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                            .font(.title2)
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.yellow)
                .padding(.top, 8)

            Text("Upgrade to Premium")
                .font(.title)
                .fontWeight(.bold)

            Text("Unlock the full power of Habit Tracker")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Benefits

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            benefitRow(icon: "infinity", title: "Unlimited Habits", subtitle: "Track as many habits as you want")
            benefitRow(icon: "calendar", title: "Full History", subtitle: "View and navigate all past weeks")
            benefitRow(icon: "icloud", title: "iCloud Sync", subtitle: "Sync across all your devices")
            benefitRow(icon: "eye.slash", title: "Ad Removal", subtitle: "Enjoy a clean, ad-free experience")
            benefitRow(icon: "paintbrush", title: "Themes", subtitle: "Personalize your tracker with themes")
            benefitRow(icon: "target", title: "Weekly Goals", subtitle: "Set and track weekly completion goals")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private func benefitRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Purchase

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            if let product = purchaseManager.product {
                Text("One-time purchase")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button(action: {
                    Task {
                        try? await purchaseManager.purchase()
                    }
                }) {
                    HStack {
                        if purchaseManager.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Upgrade for \(product.displayPrice)")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .disabled(purchaseManager.isLoading)
            } else {
                ProgressView("Loading...")
            }

            if let error = purchaseManager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Restore

    private var restoreSection: some View {
        Button(action: {
            Task {
                await purchaseManager.restorePurchases()
            }
        }) {
            Text("Restore Purchases")
                .font(.subheadline)
                .foregroundColor(.accentColor)
        }
        .disabled(purchaseManager.isLoading)
        .padding(.bottom, 8)
    }
}
