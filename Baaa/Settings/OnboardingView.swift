import SwiftUI

/// First-launch setup: language first, then his voice, then names.
/// Everything writes straight into the store so the preview is live.
struct OnboardingView: View {
    @EnvironmentObject private var store: SettingsStore
    @EnvironmentObject private var license: LicenseManager
    var onFinish: () -> Void

    @State private var step: Int
    private let steps = 3

    init(initialStep: Int = 0, onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
        _step = State(initialValue: initialStep)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PapaPreview(settings: store.settings)
                .padding(.bottom, 28)

            Group {
                switch step {
                case 0: languageStep
                case 1: toneStep
                default: namesStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            footer
        }
        .padding(EdgeInsets(top: 44, leading: 36, bottom: 28, trailing: 36))
        .frame(width: 640, height: 640)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: Steps

    private var languageStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            StepTitle(title: "Which language does Papa speak at home?",
                      detail: "Every reminder, and the buttons under it, come in this language. The English line stays underneath in grey.")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(Language.allCases) { lang in
                    ChoiceCard(selected: store.settings.language == lang) {
                        store.settings.language = lang
                    } content: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lang.displayName).font(.system(size: 15, weight: .semibold))
                            Text(lang.defaultPapaName).font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var toneStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            StepTitle(title: "How does he talk?",
                      detail: "Same reminder, three ways of putting it. You can change this any time in Settings.")
            VStack(spacing: 10) {
                ForEach(Tone.allCases) { tone in
                    let locked = tone.isPro && !license.isPro
                    ChoiceCard(selected: store.settings.tone == tone, enabled: !locked) {
                        store.settings.tone = tone
                    } content: {
                        HStack(alignment: .top, spacing: 14) {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 8) {
                                    Text(tone.displayName).font(.system(size: 15, weight: .semibold))
                                    if locked {
                                        Text("Pro").font(.system(size: 11, weight: .semibold))
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(Color.secondary.opacity(0.15), in: Capsule())
                                    }
                                }
                                Text(sample(for: tone)).font(.system(size: 13)).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
            if !license.isPro {
                Text("Strict and Filmy Papa are part of Baaapp Pro. Unlock them later from Settings, Pro.")
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
    }

    private var namesStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            StepTitle(title: "What does he call you?",
                      detail: "Leave either one empty and he'll use what a \(store.settings.language.displayName) father usually says.")
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 14) {
                GridRow {
                    Text("He calls you").foregroundStyle(.secondary)
                    TextField(store.settings.language.defaultChildName, text: $store.settings.childName)
                        .textFieldStyle(.roundedBorder)
                }
                GridRow {
                    Text("You call him").foregroundStyle(.secondary)
                    TextField(store.settings.language.defaultPapaName, text: $store.settings.papaName)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .frame(maxWidth: 420)
            Text("He'll check in at meal times, every hour for water, and at bedtime. All of it is adjustable in Settings, and he stays quiet from 10 PM to 8 AM.")
                .font(.callout).foregroundStyle(.secondary)
                .padding(.top, 6)
        }
    }

    private var footer: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(0..<steps, id: \.self) { i in
                    Circle().fill(i == step ? Color.primary : Color.secondary.opacity(0.3)).frame(width: 6, height: 6)
                }
            }
            Spacer()
            if step > 0 {
                Button("Back") { withAnimation(.easeInOut(duration: 0.2)) { step -= 1 } }
                    .keyboardShortcut(.cancelAction)
            }
            Button(step == steps - 1 ? "Start" : "Continue") {
                if step == steps - 1 { onFinish() } else { withAnimation(.easeInOut(duration: 0.2)) { step += 1 } }
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private func sample(for tone: Tone) -> String {
        let line = MessageLibrary.messages(for: .meal, language: store.settings.language, tone: tone).first
        return line?.text.substituting(settings: store.settings) ?? ""
    }
}

// MARK: - Pieces

private struct StepTitle: View {
    var title: String
    var detail: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 22, weight: .semibold))
            Text(detail).font(.system(size: 14)).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ChoiceCard<Content: View>: View {
    var selected: Bool
    var enabled: Bool = true
    var action: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        Button(action: action) {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14).padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selected ? Color.accentColor.opacity(0.10) : Color.primary.opacity(0.035))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(selected ? Color.accentColor : Color.primary.opacity(0.08), lineWidth: selected ? 1.5 : 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.55)
    }
}

/// The notch block and bubble, as they'll appear, showing his welcome line.
struct PapaPreview: View {
    var settings: AppSettings
    private var accent: Color { Color(red: 1.0, green: 0.62, blue: 0.20) }

    var body: some View {
        let pack = MessageLibrary.pack(settings.language)
        HStack(alignment: .top, spacing: 12) {
            ZStack(alignment: .bottom) {
                if let img = AvatarImageStore.shared.effectiveImage(for: .proud, allowCustom: false) {
                    Image(nsImage: img).resizable().scaledToFit().frame(height: 86)
                }
            }
            .frame(width: 124, height: 96, alignment: .bottom)
            .background(Color.black)
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 22, bottomTrailingRadius: 22))
            .shadow(color: .black.opacity(0.18), radius: 10, y: 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(settings.resolvedPapaName)
                    .font(.system(size: 11, weight: .bold)).foregroundStyle(accent)
                Text(pack.welcome.text.substituting(settings: settings))
                    .font(.system(size: 14, weight: .bold)).foregroundStyle(Color(white: 0.08))
                    .fixedSize(horizontal: false, vertical: true)
                if let english = pack.welcome.english {
                    Text(english.substituting(settings: settings))
                        .font(.system(size: 12)).foregroundStyle(Color(white: 0.46))
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: 6) {
                    Text(pack.done).font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 9).padding(.vertical, 4)
                        .background(accent, in: Capsule()).foregroundStyle(.black)
                    Text(pack.snooze).font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 9).padding(.vertical, 4)
                        .background(Color(white: 0.93), in: Capsule()).foregroundStyle(Color(white: 0.1))
                }
                .padding(.top, 4)
            }
            .padding(EdgeInsets(top: 11, leading: 14, bottom: 11, trailing: 14))
            .frame(maxWidth: 360, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.12), radius: 14, y: 6)
            .padding(.top, 6)
        }
        .animation(.easeInOut(duration: 0.15), value: settings.language)
    }
}
