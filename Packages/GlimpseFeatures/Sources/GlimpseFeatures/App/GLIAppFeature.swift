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
        public var languageFolders = GLILanguageFoldersFeature.State()

        public init(languageFolders: GLILanguageFoldersFeature.State = GLILanguageFoldersFeature.State()) {
            self.languageFolders = languageFolders
        }
    }

    @CasePathable
    public enum Action {
        case onAppear
        case languageFolders(GLILanguageFoldersFeature.Action)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Scope(state: \.languageFolders, action: \.languageFolders) {
            GLILanguageFoldersFeature()
        }
        Reduce { _, action in
            switch action {
            case .onAppear:
                return .none
            case .languageFolders:
                return .none
            }
        }
    }
}
