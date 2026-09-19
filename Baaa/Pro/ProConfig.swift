import Foundation

/// Everything about selling Baaa Pro lives here. Fill in the two TODOs after
/// creating the product in the Dodo Payments dashboard (Products → New →
/// enable "License keys", activation limit = `maxDevices`).
enum ProConfig {
    enum Environment {
        case test, live

        var apiBase: URL {
            switch self {
            case .test: return URL(string: "https://test.dodopayments.com")!
            case .live: return URL(string: "https://live.dodopayments.com")!
            }
        }

        var checkoutBase: String {
            switch self {
            case .test: return "https://test.checkout.dodopayments.com/buy/"
            case .live: return "https://checkout.dodopayments.com/buy/"
            }
        }
    }

    /// Switch to `.test` while trying purchases with Dodo's test cards.
    static let environment: Environment = .test

    /// TODO: paste the product id from the Dodo dashboard (looks like `pdt_...`).
    static let dodoProductID = "pdt_0NnvrB7JxweiL6XksiPSB"

    static let priceLabel = "$1.99"
    static let maxDevices = 2
    static let website = URL(string: "https://baaa.app")!
    static let supportEmail = "hello@baaa.app"

    /// Static payment link. Dodo appends payment_id and status when it redirects back.
    static var checkoutURL: URL {
        var c = URLComponents(string: environment.checkoutBase + dodoProductID)!
        c.queryItems = [
            URLQueryItem(name: "quantity", value: "1"),
            URLQueryItem(name: "redirect_url", value: website.appendingPathComponent("thanks").absoluteString),
            URLQueryItem(name: "metadata_source", value: "app"),
        ]
        return c.url!
    }

    static var isConfigured: Bool { !dodoProductID.contains("REPLACE_ME") }
}
