import SwiftUI
import GlimpseCore

#if canImport(UIKit)
import IssueReporting
import UIKit
#endif

/// Capture field that rejects input which would exceed `limit` (grapheme count).
struct GLICappedCaptureTextField: View {
    let title: String
    var prompt: String?
    let canonical: String
    let limit: Int
    var lineRange: ClosedRange<Int>
    #if canImport(UIKit)
    var autocapitalization: UITextAutocapitalizationType = .sentences
    #endif
    var animatesCanonicalChange: Bool
    let send: (String) -> Void

    #if canImport(UIKit)
    init(
        _ title: String,
        prompt: String? = nil,
        canonical: String,
        limit: Int,
        lineRange: ClosedRange<Int> = 1...5,
        autocapitalization: UITextAutocapitalizationType,
        animatesCanonicalChange: Bool = false,
        send: @escaping (String) -> Void
    ) {
        self.title = title
        self.prompt = prompt
        self.canonical = canonical
        self.limit = limit
        self.lineRange = lineRange
        
        self.autocapitalization = autocapitalization
        
        self.animatesCanonicalChange = animatesCanonicalChange
        self.send = send
    }
    #endif
    
    init(
        _ title: String,
        prompt: String? = nil,
        canonical: String,
        limit: Int,
        lineRange: ClosedRange<Int> = 1...5,
        animatesCanonicalChange: Bool = false,
        send: @escaping (String) -> Void
    ) {
        self.title = title
        self.prompt = prompt
        self.canonical = canonical
        self.limit = limit
        self.lineRange = lineRange
        self.animatesCanonicalChange = animatesCanonicalChange
        self.send = send
    }

    var body: some View {
        #if canImport(UIKit)
        if lineRange.upperBound <= 1 {
            CappedSingleLineTextField(
                title: title,
                prompt: prompt,
                canonical: canonical,
                limit: limit,
                autocapitalization: autocapitalization,
                send: send
            )
        } else {
            CappedMultilineTextView(
                title: title,
                prompt: prompt,
                canonical: canonical,
                limit: limit,
                lineRange: lineRange,
                autocapitalization: autocapitalization,
                animatesCanonicalChange: animatesCanonicalChange,
                send: send
            )
        }
        #else
        fallbackField
        #endif
    }

    #if !canImport(UIKit)
    @ViewBuilder
    private var fallbackField: some View {
        let binding = Binding(
            get: { canonical },
            set: send
        )
        if lineRange.upperBound <= 1 {
            TextField(
                title,
                text: binding,
                prompt: prompt.map { Text($0) }
            )
        } else {
            ZStack(alignment: .topLeading) {
                if canonical.isEmpty {
                    Text(prompt ?? title)
                        .foregroundStyle(.tertiary)
                        .allowsHitTesting(false)
                }
                TextEditor(text: binding)
            }
            .accessibilityLabel(title)
        }
    }
    #endif
}

#if canImport(UIKit)
// MARK: - Multiline (Word / Meaning / Example)

private struct CappedMultilineTextView: UIViewRepresentable {
    let title: String
    let prompt: String?
    let canonical: String
    let limit: Int
    let lineRange: ClosedRange<Int>
    let autocapitalization: UITextAutocapitalizationType
    let animatesCanonicalChange: Bool
    let send: (String) -> Void

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func makeCoordinator() -> CappedTextCoordinator {
        CappedTextCoordinator(limit: limit, lastSent: canonical, send: send)
    }

    func makeUIView(context: Context) -> CappedLineTextView {
        let textView = CappedLineTextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.adjustsFontForContentSizeCategory = true
        textView.textColor = .label
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textView.minLineCount = lineRange.lowerBound
        textView.maxLineCount = lineRange.upperBound
        textView.placeholderText = prompt ?? title
        textView.text = canonical
        textView.syncPlaceholder()
        applyChrome(textView, context: context)
        return textView
    }

    func updateUIView(_ textView: CappedLineTextView, context: Context) {
        context.coordinator.limit = limit
        context.coordinator.send = send
        textView.minLineCount = lineRange.lowerBound
        textView.maxLineCount = lineRange.upperBound
        textView.placeholderText = prompt ?? title
        applyChrome(textView, context: context)

        if textView.text != canonical, context.coordinator.lastSent != canonical {
            context.coordinator.lastSent = canonical
            if animatesCanonicalChange {
                DispatchQueue.main.async {
                    UIView.transition(
                        with: textView,
                        duration: 0.2,
                        options: [.transitionCrossDissolve, .curveEaseInOut, .allowUserInteraction]
                    ) {
                        textView.text = canonical
                        textView.syncPlaceholder()
                        textView.invalidateIntrinsicContentSizeIfNeeded()
                    }
                }
            } else {
                textView.text = canonical
                textView.syncPlaceholder()
                textView.invalidateIntrinsicContentSizeIfNeeded()
            }
            return
        }
        textView.syncPlaceholder()
        textView.invalidateIntrinsicContentSizeIfNeeded()
    }

    private func applyChrome(_ textView: CappedLineTextView, context: Context) {
        _ = dynamicTypeSize
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        if textView.isEditable != isEnabled {
            textView.isEditable = isEnabled
        }
        textView.returnKeyType = .done
        textView.inputAccessoryView = nil
        textView.autocapitalizationType = autocapitalization
        context.coordinator.syncPlaceholder = { [weak textView] in
            textView?.syncPlaceholder()
            textView?.invalidateIntrinsicContentSizeIfNeeded()
        }
    }
}

// MARK: - Single line (folder name)

private struct CappedSingleLineTextField: UIViewRepresentable {
    let title: String
    let prompt: String?
    let canonical: String
    let limit: Int
    let autocapitalization: UITextAutocapitalizationType
    let send: (String) -> Void

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func makeCoordinator() -> CappedTextCoordinator {
        CappedTextCoordinator(limit: limit, lastSent: canonical, send: send)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.adjustsFontForContentSizeCategory = true
        textField.textColor = .label
        textField.returnKeyType = .done
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.addTarget(
            context.coordinator,
            action: #selector(CappedTextCoordinator.editingChanged(_:)),
            for: .editingChanged
        )
        textField.placeholder = prompt ?? title
        textField.text = canonical
        applyChrome(textField, context: context)
        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        context.coordinator.limit = limit
        context.coordinator.send = send
        textField.placeholder = prompt ?? title
        applyChrome(textField, context: context)

        if textField.text != canonical, context.coordinator.lastSent != canonical {
            textField.text = canonical
            context.coordinator.lastSent = canonical
        }
    }

    private func applyChrome(_ textField: UITextField, context: Context) {
        _ = dynamicTypeSize
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        if textField.isEnabled != isEnabled {
            textField.isEnabled = isEnabled
        }
        textField.autocapitalizationType = autocapitalization
        context.coordinator.syncPlaceholder = {}
    }
}

// MARK: - Shared coordinator

private final class CappedTextCoordinator: NSObject, UITextViewDelegate, UITextFieldDelegate {
    var limit: Int
    var lastSent: String
    var send: (String) -> Void
    var syncPlaceholder: () -> Void = {}

    init(
        limit: Int,
        lastSent: String,
        send: @escaping (String) -> Void
    ) {
        self.limit = limit
        self.lastSent = lastSent
        self.send = send
    }

    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return applyDecision(
            current: textView.text ?? "",
            utf16Range: range,
            replacement: text
        ) { newText, cursorUTF16 in
            textView.text = newText
            let safeCursor = min(cursorUTF16, newText.utf16.count)
            textView.selectedRange = NSRange(location: safeCursor, length: 0)
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        emit(textView.text ?? "")
        syncPlaceholder()
    }

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        applyDecision(
            current: textField.text ?? "",
            utf16Range: range,
            replacement: string
        ) { newText, cursorUTF16 in
            textField.text = newText
            let safeCursor = min(cursorUTF16, newText.utf16.count)
            if let position = textField.position(
                from: textField.beginningOfDocument,
                offset: safeCursor
            ) {
                textField.selectedTextRange = textField.textRange(from: position, to: position)
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @objc
    func editingChanged(_ textField: UITextField) {
        emit(textField.text ?? "")
    }

    private func applyDecision(
        current: String,
        utf16Range: NSRange,
        replacement: String,
        apply: (String, Int) -> Void
    ) -> Bool {
        switch GLICaptureFieldLimits.changeDecision(
            current: current,
            utf16Range: utf16Range,
            replacement: replacement,
            limit: limit
        ) {
        case .allow:
            return true
        case .reject:
            return false
        case .apply(let newText, let cursorUTF16):
            apply(newText, cursorUTF16)
            emit(newText)
            syncPlaceholder()
            return false
        }
    }

    private func emit(_ text: String) {
        lastSent = text
        send(text)
    }
}

// MARK: - Growing UITextView

private final class CappedLineTextView: UITextView {
    var minLineCount = 1
    var maxLineCount = 5
    var placeholderText: String? {
        didSet { placeholderLabel.text = placeholderText }
    }

    private let placeholderLabel = UILabel()
    private var lastLayoutWidth: CGFloat = 0
    private var lastReportedIntrinsicHeight: CGFloat?

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        isScrollEnabled = false
        placeholderLabel.textColor = .placeholderText
        placeholderLabel.numberOfLines = 0
        placeholderLabel.adjustsFontForContentSizeCategory = true
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(placeholderLabel)
        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor.constraint(equalTo: topAnchor),
            placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            placeholderLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        reportIssue("CappedLineTextView does not support init(coder:)")
        return nil
    }

    override var font: UIFont? {
        didSet { placeholderLabel.font = font }
    }

    override var intrinsicContentSize: CGSize {
        let resolvedFont = font ?? UIFont.preferredFont(forTextStyle: .body)
        let lineHeight = resolvedFont.lineHeight
        let minHeight = lineHeight * CGFloat(minLineCount)
        let maxHeight = lineHeight * CGFloat(maxLineCount)
        let width = bounds.width > 0 ? bounds.width : .greatestFiniteMagnitude
        let fitting = sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        let height = min(max(fitting.height, minHeight), maxHeight)
        return CGSize(width: UIView.noIntrinsicMetric, height: ceil(height))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.width != lastLayoutWidth {
            lastLayoutWidth = bounds.width
            lastReportedIntrinsicHeight = nil
            invalidateIntrinsicContentSize()
        }
        let resolvedFont = font ?? UIFont.preferredFont(forTextStyle: .body)
        let maxHeight = resolvedFont.lineHeight * CGFloat(maxLineCount)
        let width = bounds.width > 0 ? bounds.width : .greatestFiniteMagnitude
        let fitting = sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        let shouldScroll = fitting.height > maxHeight + 0.5
        if isScrollEnabled != shouldScroll {
            isScrollEnabled = shouldScroll
        }
    }

    func syncPlaceholder() {
        placeholderLabel.isHidden = !(text ?? "").isEmpty
    }

    func invalidateIntrinsicContentSizeIfNeeded() {
        let newHeight = intrinsicContentSize.height
        guard lastReportedIntrinsicHeight != newHeight else { return }
        lastReportedIntrinsicHeight = newHeight
        invalidateIntrinsicContentSize()
    }
}
#endif
