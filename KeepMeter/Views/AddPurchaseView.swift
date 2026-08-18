import SwiftUI
import SwiftData

struct AddPurchaseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var merchant = ""
    @State private var priceText = ""
    @State private var purchaseDate = Date()
    @State private var returnDeadline = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    @State private var wantsReminders = true

    private var parsedPrice: Double? {
        let normalized = priceText
            .replacingOccurrences(of: Locale.current.groupingSeparator ?? ".", with: "")
            .replacingOccurrences(of: Locale.current.decimalSeparator ?? ",", with: ".")
        return Double(normalized)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (parsedPrice ?? -1) >= 0 &&
        returnDeadline >= purchaseDate
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Purchase")) {
                    TextField(String(localized: "Item name"), text: $name)
                    TextField(String(localized: "Merchant (optional)"), text: $merchant)
                    TextField(String(localized: "Price"), text: $priceText)
                        .keyboardType(.decimalPad)
                }

                Section(String(localized: "Dates")) {
                    DatePicker(
                        String(localized: "Purchased"),
                        selection: $purchaseDate,
                        displayedComponents: .date
                    )

                    DatePicker(
                        String(localized: "Return by"),
                        selection: $returnDeadline,
                        in: purchaseDate...,
                        displayedComponents: .date
                    )
                }

                Section {
                    Toggle(String(localized: "Return reminders"), isOn: $wantsReminders)
                } footer: {
                    Text(String(localized: "KeepMeter treats the return date as information you confirm. Merchant policies and legal rights can differ."))
                }
            }
            .navigationTitle(String(localized: "New purchase"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        guard let price = parsedPrice else { return }

        let purchase = Purchase(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            merchant: merchant.trimmingCharacters(in: .whitespacesAndNewlines),
            price: price,
            purchaseDate: purchaseDate,
            returnDeadline: returnDeadline
        )

        modelContext.insert(purchase)
        try? modelContext.save()

        if wantsReminders {
            Task {
                _ = await NotificationManager.requestAuthorization()
                await NotificationManager.scheduleReturnReminders(for: purchase)
            }
        }

        dismiss()
    }
}
