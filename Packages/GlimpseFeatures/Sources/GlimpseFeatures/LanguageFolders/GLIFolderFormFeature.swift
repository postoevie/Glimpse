import ComposableArchitecture
import GlimpseCore

/// Name-only create / rename sheet for custom folders.
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

        public var canSave: Bool {
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        public var navigationTitle: String {
            switch mode {
            case .rename:
                return "Rename Folder"
            case .create:
                return "New Folder"
            }
        }

        public init(mode: Mode, name: String = "") {
            self.mode = mode
            self.name = name
        }
    }

    @CasePathable
    public enum Action {
        case nameChanged(String)
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

            case .cancelButtonTapped:
                return .run { [dismiss] _ in
                    await dismiss()
                }

            case .saveButtonTapped:
                let trimmed = state.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    return .none
                }
                state.name = trimmed
                return .send(.delegate(.saved))

            case .delegate:
                return .none
            }
        }
    }
}
