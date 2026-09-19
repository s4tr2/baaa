import Foundation
import Combine
import AppKit

/// Activates and validates Dodo Payments license keys. One key, up to
/// `ProConfig.maxDevices` activations; each Mac gets its own instance id.
@MainActor
final class LicenseManager: ObservableObject {
    static let shared = LicenseManager()

    enum State: Equatable {
        case free
        case pro(key: String, instanceID: String, activatedAt: Date)
    }

    /// Who bought it, from Dodo's activation response. Shown in Settings → Pro.
    @Published private(set) var licensedTo: String?

    @Published private(set) var state: State
    @Published private(set) var isBusy = false
    @Published var lastError: String?

    var isPro: Bool {
        if case .pro = state { return true }
        return false
    }

    var maskedKey: String? {
        guard case .pro(let key, _, _) = state else { return nil }
        let tail = key.suffix(4)
        return "••••-••••-" + tail
    }

    private let defaults = UserDefaults.standard
    private let stateKey = "app.baaa.license.v1"
    private let validatedKey = "app.baaa.license.validated"
    private let revalidateAfter: TimeInterval = 3 * 24 * 3600
    private let offlineGrace: TimeInterval = 30 * 24 * 3600

    private struct Stored: Codable {
        var key: String
        var instanceID: String
        var activatedAt: Date
        var email: String?
    }

    private init() {
        if let data = defaults.data(forKey: stateKey),
           let s = try? JSONDecoder().decode(Stored.self, from: data) {
            state = .pro(key: s.key, instanceID: s.instanceID, activatedAt: s.activatedAt)
            licensedTo = s.email
        } else {
            state = .free
        }
    }

    // MARK: - Public

    func activate(key rawKey: String) async {
        let key = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { lastError = "Paste the license key from your email first."; return }
        isBusy = true
        lastError = nil
        defer { isBusy = false }
        do {
            let instance: ActivateResponse = try await post("licenses/activate",
                                                          body: ["license_key": key, "name": Host.current().localizedName ?? "Mac"])
            // A valid key for some other product of yours shouldn't unlock Baaa.
            if ProConfig.isConfigured, let pid = instance.product?.product_id, pid != ProConfig.dodoProductID {
                let _: EmptyResponse? = try? await post("licenses/deactivate",
                                                       body: ["license_key": key, "license_key_instance_id": instance.id])
                lastError = "That key belongs to a different product."
                return
            }
            let email = instance.customer?.email
            persist(Stored(key: key, instanceID: instance.id, activatedAt: Date(), email: email))
            defaults.set(Date(), forKey: validatedKey)
            licensedTo = email
            state = .pro(key: key, instanceID: instance.id, activatedAt: Date())
        } catch {
            lastError = friendly(error)
        }
    }

    func deactivate() async {
        guard case .pro(let key, let instanceID, _) = state else { return }
        isBusy = true
        lastError = nil
        defer { isBusy = false }
        do {
            let _: EmptyResponse = try await post("licenses/deactivate",
                                                 body: ["license_key": key, "license_key_instance_id": instanceID])
        } catch {
            // Deactivation failing (offline, already removed) shouldn't trap the user on this Mac.
            NSLog("Baaa: deactivate failed: \(error)")
        }
        clear()
    }

    /// Called on launch. Re-checks with Dodo every few days; tolerates being offline.
    func validateIfNeeded() {
        guard case .pro(let key, let instanceID, _) = state else { return }
        let last = defaults.object(forKey: validatedKey) as? Date ?? .distantPast
        guard Date().timeIntervalSince(last) > revalidateAfter else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                let r: ValidateResponse = try await post("licenses/validate",
                                                         body: ["license_key": key, "license_key_instance_id": instanceID])
                if r.valid {
                    defaults.set(Date(), forKey: validatedKey)
                } else {
                    clear()
                    lastError = "This license key is no longer valid on this Mac."
                }
            } catch let e as APIError where e.isDefinitive {
                clear()
                lastError = friendly(e)
            } catch {
                // Network trouble: keep Pro for a generous grace window.
                if Date().timeIntervalSince(last) > offlineGrace { clear() }
            }
        }
    }

    func openCheckout() {
        NSWorkspace.shared.open(ProConfig.checkoutURL)
    }

    // MARK: - Persistence

    private func persist(_ s: Stored) {
        if let data = try? JSONEncoder().encode(s) { defaults.set(data, forKey: stateKey) }
    }

    private func clear() {
        defaults.removeObject(forKey: stateKey)
        defaults.removeObject(forKey: validatedKey)
        licensedTo = nil
        state = .free
    }

    // MARK: - Dodo API

    private struct ActivateResponse: Decodable {
        struct Product: Decodable { let product_id: String }
        struct Customer: Decodable { let email: String?; let name: String? }
        let id: String
        let product: Product?
        let customer: Customer?
    }
    private struct ValidateResponse: Decodable { let valid: Bool }
    private struct EmptyResponse: Decodable {}

    struct APIError: LocalizedError {
        let status: Int
        let message: String
        var errorDescription: String? { message }
        /// 4xx means Dodo understood us and said no; 5xx or transport errors mean "try later".
        var isDefinitive: Bool { (400..<500).contains(status) }
    }

    private func post<T: Decodable>(_ path: String, body: [String: String]) async throws -> T {
        var req = URLRequest(url: ProConfig.environment.apiBase.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 20
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            let msg = (try? JSONDecoder().decode(DodoErrorBody.self, from: data))?.message
            throw APIError(status: status, message: msg ?? "Dodo Payments returned \(status).")
        }
        if data.isEmpty, let empty = EmptyResponse() as? T { return empty }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private struct DodoErrorBody: Decodable { let message: String? }

    private func friendly(_ error: Error) -> String {
        if let e = error as? APIError {
            switch e.status {
            // Codes as documented by Dodo for /licenses/activate.
            case 404: return "That key wasn't found. Check for typos, or copy it again from the email."
            case 422: return "This key is already active on \(ProConfig.maxDevices) Macs. Deactivate it on one of them first."
            case 403: return "This key has been disabled or refunded. Write to \(ProConfig.supportEmail) if that's a surprise."
            case 400: return e.message
            default: return e.message
            }
        }
        if (error as? URLError) != nil { return "Couldn't reach Dodo Payments. Check your connection and try again." }
        return error.localizedDescription
    }
}
