import ComposableArchitecture
import Foundation
import GlimpseCore

// Task: I1-T4 — docs/planning/l1-capture/I1-T4-word-card/
@Reducer
public struct GLIWordCardFeature {
    @ObservableState
    public struct State: Equatable {
        public var wordPair: GLIWordPair
        public var example: String?
        public var didFailExampleLoad = false

        public init(
            wordPair: GLIWordPair,
            example: String? = nil,
            didFailExampleLoad: Bool = false
        ) {
            self.wordPair = wordPair
            self.example = example
            self.didFailExampleLoad = didFailExampleLoad
        }
    }

    @CasePathable
    public enum Action: ViewAction, Equatable {
        public enum View: Equatable {
            case onAppear
        }

        case view(View)
        case exampleLoaded(String)
        case exampleLoadFailed
    }

    private enum CancelID {
        case loadExample
    }

    @Dependency(\.wordExamples) private var wordExamples

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                state.didFailExampleLoad = false
                state.example = nil
                let wordID = state.wordPair.id
                return .run { [wordExamples] send in
                    do {
                        let example = try await wordExamples.fetchExample(wordID)
                        await send(.exampleLoaded(example))
                    } catch is CancellationError {
                        return
                    } catch {
                        await send(.exampleLoadFailed)
                    }
                }
                .cancellable(id: CancelID.loadExample, cancelInFlight: true)

            case let .exampleLoaded(example):
                state.didFailExampleLoad = false
                state.example = example
                return .none

            case .exampleLoadFailed:
                state.didFailExampleLoad = true
                return .none
            }
        }
    }
}
