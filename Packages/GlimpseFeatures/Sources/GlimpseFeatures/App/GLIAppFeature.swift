import ComposableArchitecture
import GlimpseAI
import GlimpseCore

/// Root navigation shell (partial X3). Child destinations land in I1+.
@Reducer
public struct GLIAppFeature {
    /// Compile-time anchors so Core + AI stay in the Features graph (I0).
    public static let appGroupIdentifier = GLIAppGroup.identifier
    public static let stubGeneration: any GLIGenerationServiceType = GLIUnimplementedGenerationService()

    @ObservableState
    public struct State: Equatable {
        public var wordsFolder = GLIWordsFolderFeature.State()

        public init(wordsFolder: GLIWordsFolderFeature.State = GLIWordsFolderFeature.State()) {
            self.wordsFolder = wordsFolder
        }
    }

    @CasePathable
    public enum Action {
        case onAppear
        case wordsFolder(GLIWordsFolderFeature.Action)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Scope(state: \.wordsFolder, action: \.wordsFolder) {
            GLIWordsFolderFeature()
        }
        Reduce { _, action in
            switch action {
            case .onAppear:
                return .none
            case .wordsFolder:
                return .none
            }
        }
    }
}
