import ComposableArchitecture
import Foundation
import GlimpseCore
import SwiftUI

public struct GLIWordCardView: View {
    @Bindable public var store: StoreOf<GLIWordCardFeature>

    public init(store: StoreOf<GLIWordCardFeature>) {
        self.store = store
    }

    public var body: some View {
        List {
            Section("Word") {
                Text(store.wordPair.word)
                    .font(.title2.bold())
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel("Word")
                    .accessibilityValue(Text(store.wordPair.word))
            }

            Section("Translation") {
                if store.wordPair.translation.isEmpty {
                    Text("No translation")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Translation")
                        .accessibilityValue("No translation")
                } else {
                    Text(store.wordPair.translation)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("Translation")
                        .accessibilityValue(Text(store.wordPair.translation))
                }
            }

            Section("Example") {
                if store.didFailExampleLoad {
                    Text("Couldn't load example")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Example")
                        .accessibilityValue("Couldn't load example")
                } else if let example = store.example {
                    if example.isEmpty {
                        Text("No example")
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Example")
                            .accessibilityValue("No example")
                    } else {
                        Text(example)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel("Example")
                            .accessibilityValue(Text(example))
                    }
                } else {
                    HStack {
                        Text("Loading example")
                        Spacer()
                        ProgressView()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Loading example")
                }
            }

            Section("Languages") {
                LabeledContent(
                    "Source",
                    value: languageName(for: store.wordPair.sourceLanguage)
                )
                .accessibilityLabel("Source language")
                .accessibilityValue(Text(
                    languageName(for: store.wordPair.sourceLanguage)
                ))

                LabeledContent(
                    "Target",
                    value: languageName(for: store.wordPair.targetLanguage)
                )
                .accessibilityLabel("Target language")
                .accessibilityValue(Text(
                    languageName(for: store.wordPair.targetLanguage)
                ))
            }
        }
        .navigationTitle("Word card")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await store.send(.view(.onAppear)).finish()
        }
    }

    private func languageName(for code: String?) -> String {
        guard let code, !code.isEmpty else {
            return "Unknown"
        }
        return Locale.current.localizedString(forLanguageCode: code) ?? code
    }
}
