import SwiftUI

struct SettingsView: View {
    @Environment(OpsStore.self) private var store
    @State private var token = ""

    var body: some View {
        @Bindable var store = store

        Form {
            Section("Mode") {
                Toggle("Demo mode", isOn: $store.isDemoMode)
                Text("Demo mode is enabled by default and works offline with deterministic fixtures.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Live API") {
                TextField("Base URL", text: $store.liveBaseURL)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .disabled(store.isDemoMode)

                SecureField("API token", text: $token)
                    .textInputAutocapitalization(.never)
                    .disabled(store.isDemoMode)

                HStack {
                    Button {
                        store.saveToken(token)
                        token = ""
                    } label: {
                        Label("Save Token", systemImage: "key")
                    }
                    .disabled(store.isDemoMode || token.isEmpty)

                    Button(role: .destructive) {
                        store.clearToken()
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                    .disabled(store.isDemoMode)
                }

                Button {
                    Task { await store.testLiveConnection() }
                } label: {
                    Label("Test Connection", systemImage: "network")
                }
                .disabled(store.isDemoMode)

                Text(store.lastConnectionStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Security") {
                Label("Tokens are stored in Keychain and are never logged.", systemImage: "lock.shield")
                Label("Reference runbook commands are not executable.", systemImage: "terminal")
            }
        }
        .navigationTitle("Settings")
    }
}
