import ComposableArchitecture
import GlimpseAI
import GlimpseCore

/// Root navigation shell (partial X3). Child destinations land in I1+.
@Reducer
public struct AppFeature {
    /// Compile-time anchors so Core + AI stay in the Features graph (I0).
    public static let appGroupIdentifier = AppGroup.identifier
    public static let stubGeneration: any GenerationService = UnimplementedGenerationService()

    @ObservableState
    public struct State: Equatable {
        public var searchText = ""

        public init(searchText: String = "") {
            self.searchText = searchText
        }
    }

    public enum Action {
        case onAppear
        case searchTextChanged(String)
        case addButtonTapped
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
            case let .searchTextChanged(text):
                state.searchText = text
                return .none
            case .addButtonTapped:
                // Capture sheet — Increment I1
                return .none
            }
        }
    }
}
