import SwiftUI

struct ProSettingsView: View {
    @EnvironmentObject private var license: LicenseManager
    @State private var keyInput = ""

    var body: some View {
        Form {
            Section {
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: license.isPro ? "checkmark.seal.fill" : "seal")
                        .font(.system(size: 34))
                        .foregroundStyle(license.isPro ? Color(red: 1.0, green: 0.62, blue: 0.20) : .secondary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(license.isPro ? "Baaa Pro is active on this Mac" : "Baaa Pro")
                            .font(.title3.weight(.semibold))
                        if let masked = license.maskedKey {
                            Text(license.licensedTo.map { "License \(masked) · \($0)" } ?? "License \(masked)")
                                .foregroundStyle(.secondary)
                        } else {
                            Text("One-time \(ProConfig.priceLabel). Use it on \(ProConfig.maxDevices) Macs. No subscription, no account.")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 6)
            }

            if !license.isPro {
                Section("What Pro unlocks") {
                    ForEach(ProFeature.allCases, id: \.self) { f in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: f.symbol).frame(width: 22).foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(f.title)
                                Text(f.detail).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    HStack {
                        Button {
                            license.openCheckout()
                        } label: {
                            Label("Get Baaa Pro for \(ProConfig.priceLabel)", systemImage: "cart.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!ProConfig.isConfigured)
                        if !ProConfig.isConfigured {
                            Text("Checkout link not configured yet (see ProConfig.swift).")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }

                Section {
                    HStack {
                        TextField("XXXX-XXXX-XXXX-XXXX", text: $keyInput)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit { Task { await license.activate(key: keyInput) } }
                        Button("Activate") { Task { await license.activate(key: keyInput) } }
                            .disabled(license.isBusy || keyInput.trimmingCharacters(in: .whitespaces).isEmpty)
                        if license.isBusy { ProgressView().controlSize(.small) }
                    }
                    if let err = license.lastError {
                        Label(err, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                } header: {
                    Text("Already bought it?")
                } footer: {
                    Text("Your license key was emailed to you by Dodo Payments right after checkout. Lost it? Write to \(ProConfig.supportEmail).")
                }
            } else {
                Section {
                    HStack {
                        Button("Deactivate on this Mac") { Task { await license.deactivate() } }
                            .disabled(license.isBusy)
                        if license.isBusy { ProgressView().controlSize(.small) }
                        Spacer()
                    }
                    if let err = license.lastError {
                        Label(err, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red).font(.callout)
                    }
                } footer: {
                    Text("Frees up one of your \(ProConfig.maxDevices) activations so you can use the key on another Mac.")
                }
            }
        }
        .formStyle(.grouped)
    }
}

/// Small inline nudge toward the Pro tab, used under locked sections.
struct ProUpsell: View {
    var feature: ProFeature
    @EnvironmentObject private var tabs: SettingsTabModel

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill").foregroundStyle(.secondary)
            Text("\(feature.title) is part of Baaa Pro.")
                .foregroundStyle(.secondary)
            Button("Unlock for \(ProConfig.priceLabel)") { tabs.selected = .pro }
                .controlSize(.small)
        }
        .font(.callout)
    }
}
