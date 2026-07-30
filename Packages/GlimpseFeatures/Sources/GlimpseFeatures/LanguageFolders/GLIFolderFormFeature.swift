import ComposableArchitecture
import GlimpseCore

/// Create / rename sheet for custom folders (create requires source language).
@Reducer
public struct GLIFolderFormFeature {
    @ObservableState
    public struct State: Equatable {
        public enum Mode: Equatable, Sendable {
            case create
            case rename(GLICustomFolder.ID)
        }

        public var mode: Mode
        public var name: String
        /// Set at create; unused / not edited in rename mode.
        public var sourceLanguage: String?

        public var canSave: Bool {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return false }
            switch mode {
            case .create:
                guard let sourceLanguage, !sourceLanguage.isEmpty else { return false }
                return true
            case .rename:
                return true
            }
        }

        public var showsSourceLanguagePicker: Bool {
            if case .create = mode { return true }
            return false
        }

        public var navigationTitle: String {
            switch mode {
            case .rename:
                return "Rename Folder"
            case .create:
                return "New Folder"
            }
        }

        public init(mode: Mode, name: String = "", sourceLanguage: String? = nil) {
            self.mode = mode
            self.name = name
            self.sourceLanguage = sourceLanguage
        }
    }

    @CasePathable
    public enum Action {
        case nameChanged(String)
        case sourceLanguageChanged(String?)
        case cancelButtonTapped
        case saveButtonTapped
        case delegate(Delegate)

        @CasePathable
        public enum Delegate {
            case saved
        }
    }

    @Dependency(\.dismiss) var dismiss

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .nameChanged(name):
                state.name = name
                return .none

            case let .sourceLanguageChanged(code):
                state.sourceLanguage = code
                return .none

            case .cancelButtonTapped:
                return .run { [dismiss] _ in
                    await dismiss()
                }

            case .saveButtonTapped:
                let trimmed = state.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    return .none
                }
                if case .create = state.mode {
                    guard let source = state.sourceLanguage, !source.isEmpty else {
                        return .none
                    }
                }
                state.name = trimmed
                return .send(.delegate(.saved))

            case .delegate:
                return .none
            }
        }
    }
}
