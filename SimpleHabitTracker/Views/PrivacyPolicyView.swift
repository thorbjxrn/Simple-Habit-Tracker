import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Last updated: April 15, 2026")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                section("Overview") {
                    "Simple Habit Tracker is designed with your privacy in mind. The app does not require an account, does not collect personal information, and stores your habit data locally on your device."
                }

                section("Data We Store") {
                    """
                    Your habit names, completion history, and preferences are stored locally on your device using Apple's SwiftData framework. This data never leaves your device unless you enable iCloud Sync (premium feature), in which case it is synced through Apple's iCloud service under your Apple Account. We do not have access to your iCloud data.
                    """
                }

                section("Advertising") {
                    """
                    The free version of the app displays ads provided by Google AdMob. AdMob may collect device identifiers, ad interaction data, and approximate location to serve relevant ads. Before any tracking occurs, the app will ask for your permission through Apple's App Tracking Transparency prompt. You can change this preference at any time in your device's Settings under Privacy & Security > Tracking.

                    Premium users do not see any ads, and no ad-related data is collected for them.
                    """
                }

                section("Third-Party Services") {
                    """
                    Google AdMob: Used to display ads in the free version. See Google's privacy policy at https://policies.google.com/privacy

                    Apple StoreKit: Used to process in-app purchases. Transactions are handled entirely by Apple.

                    Apple iCloud: Used for optional data sync (premium). Managed under your Apple Account and Apple's privacy policy.
                    """
                }

                section("Data Collection Summary") {
                    """
                    We do not collect, store, or transmit any personal information to our own servers. We do not have servers. All data processing happens on your device or through Apple and Google services as described above.
                    """
                }

                section("Children's Privacy") {
                    "This app is not directed at children under the age of 13. We do not knowingly collect personal information from children."
                }

                section("Data Retention") {
                    "Your habit data is stored on your device until you delete the app. If you use iCloud Sync, your data is retained in iCloud until you delete it or disable sync. We have no ability to access or delete your data."
                }

                section("Your Rights") {
                    "Since all data is stored locally on your device (or in your personal iCloud account), you have full control over it. You can delete the app at any time to remove all local data."
                }

                section("Changes to This Policy") {
                    "We may update this privacy policy from time to time. Any changes will be reflected in the app and on our website with an updated date."
                }

                section("Contact") {
                    "If you have questions about this privacy policy, please contact us at app.chair433@passfwd.com."
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, content: () -> String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(content())
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
