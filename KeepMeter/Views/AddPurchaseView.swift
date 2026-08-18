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
    @State private var showingSaveError = false

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
            ZStack {
                KMBackground()

                Form {
                    Section {
                        introCard
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }

                    Section(String(localized: "Purchase")) {
                        Label {
                            TextField(String(localized: "Item name"), text: $name)
                                .textInputAutocapitalization(.sentences)
                        } icon: {
                            Image(systemName: "shippingbox.fill")
                                .foregroundStyle(KMTheme.accent)
                        }

                        Label {
                            TextField(String(localized: "Merchant (optional)"), text: $merchant)
                                .textInputAutocapitalization(.words)
                        } icon: {
                            Image(systemName: "storefront.fill")
                                .foregroundStyle(KMTheme.accentSoft)
                        }

                        Label {
                            TextField(String(localized: "Price"), text: $priceText)
                                .keyboardType(.decimalPad)
                        } icon: {
                            Image(systemName: "eurosign.circle.fill")
                                .foregroundStyle(KMTheme.success)
                        }
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
                        Toggle(isOn: $wantsReminders) {
                            Label(String(localized: "Return reminders"), systemImage: "bell.badge.fill")
                        }
                        .tint(KMTheme.accent)
                    } footer: {
                        Text(String(localized: "KeepMeter treats the return date as information you confirm. Merchant policies and legal rights can differ."))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(String(localized: "New purchase"))
            .navigationBarTitleDisplayMode(.inline)
            .tint(KMTheme.accent)
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
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
            .alert(String(localized: "Save"), isPresented: $showingSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(String(localized: "The purchase could not be saved. Please try again."))
            }
        }
    }

    private var introCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(KMTheme.accent.opacity(0.12))
                Image(systemName: "timer")
                    .font(.title2.bold())
                    .foregroundStyle(KMTheme.accent)
            }
            .frame(width: 54, height: 54)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(String(localized: "Start the decision clock"))
                    .font(.headline)
                Text(String(localized: "Add the real return deadline, then track how often the purchase earns its place."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .kmCard()
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
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

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            showingSaveError = true
            return
        }

        if wantsReminders {
            Task {
                _ = await NotificationManager.requestAuthorization()
                await NotificationManager.scheduleReturnReminders(for: purchase)
            }
        }

        dismiss()
    }
}
