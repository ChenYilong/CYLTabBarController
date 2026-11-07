# Representable Recipes

Complete working recipes for common UIKit wrapping scenarios. Each recipe includes the full `UIViewRepresentable` or `UIViewControllerRepresentable` struct, the Coordinator with delegate methods, a SwiftUI usage example, and gotchas specific to that wrapper.

---

## Contents

- [1. MKMapView Wrapper](#1-mkmapview-wrapper)
- [2. UITextView Wrapper (Attributed Text)](#2-uitextview-wrapper-attributed-text)
- [3. AVCaptureVideoPreviewLayer Wrapper](#3-avcapturevideopreviewlayer-wrapper)
- [4. PHPickerViewController Wrapper](#4-phpickerviewcontroller-wrapper)
- [5. MFMailComposeViewController Wrapper](#5-mfmailcomposeviewcontroller-wrapper)
- [6. UIActivityViewController Wrapper (Share Sheet)](#6-uiactivityviewcontroller-wrapper-share-sheet)
- [7. UISearchBar Wrapper](#7-uisearchbar-wrapper)
- [8. PDFView Wrapper (PDFKit)](#8-pdfview-wrapper-pdfkit)
- [9. MFMessageComposeViewController Wrapper](#9-mfmessagecomposeviewcontroller-wrapper)

> Native WebKit for SwiftUI now covers modern embedded web content on iOS 26+. See the `swiftui-webkit` skill for `WebView`, `WebPage`, navigation policies, JavaScript calls, and migration guidance. Keep this file focused on generic representable patterns.

## 1. MKMapView Wrapper

Display a map with annotations, track region changes, and toggle map type.

```swift
import SwiftUI
import MapKit

struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var mapType: MKMapType
    var annotations: [MKPointAnnotation]
    var onRegionChanged: ((MKCoordinateRegion) -> Void)?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Update map type
        if uiView.mapType != mapType {
            uiView.mapType = mapType
        }

        // Update region -- guard against tiny differences to avoid feedback loops
        let currentCenter = uiView.region.center
        let threshold = 0.0001
        if abs(currentCenter.latitude - region.center.latitude) > threshold ||
           abs(currentCenter.longitude - region.center.longitude) > threshold {
            uiView.setRegion(region, animated: true)
        }

        // Diff annotations
        let existing = Set(uiView.annotations.compactMap { $0 as? MKPointAnnotation })
        let incoming = Set(annotations)
        let toRemove = existing.subtracting(incoming)
        let toAdd = incoming.subtracting(existing)
        uiView.removeAnnotations(Array(toRemove))
        uiView.addAnnotations(Array(toAdd))
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable

        init(_ parent: MapViewRepresentable) { self.parent = parent }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
            parent.onRegionChanged?(mapView.region)
        }

        func mapView(
            _ mapView: MKMapView,
            viewFor annotation: MKAnnotation
        ) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            let id = "pin"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: id)
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.annotation = annotation
            return view
        }
    }
}
```

### Usage

```swift
struct MapScreen: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var mapType: MKMapType = .standard

    var body: some View {
        MapViewRepresentable(
            region: $region,
            mapType: $mapType,
            annotations: []
        )
        .ignoresSafeArea()
    }
}
```

### Gotchas

- **Region update loops.** The delegate writes to `@Binding region`, which triggers `updateUIView`, which calls `setRegion`, which triggers the delegate again. The threshold guard is essential.
- **Annotation diffing.** MKMapView does not handle duplicate annotations well. Always diff before adding/removing.
- **Native SwiftUI Map.** For iOS 17+, prefer the native `Map` view unless you need delegate-level control (custom overlays, clustering, etc.).

---

## 2. UITextView Wrapper (Attributed Text)

Wrap `UITextView` for rich text editing with `NSAttributedString` binding and placeholder support.

```swift
import SwiftUI

struct RichTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    var placeholder: String = ""
    @Binding var isFirstResponder: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)

        // Placeholder label
        let label = UILabel()
        label.text = placeholder
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .placeholderText
        label.tag = 999
        label.translatesAutoresizingMaskIntoConstraints = false
        textView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: textView.topAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 8),
        ])

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.attributedText != attributedText {
            uiView.attributedText = attributedText
        }

        // Update placeholder visibility
        if let label = uiView.viewWithTag(999) as? UILabel {
            label.isHidden = !uiView.text.isEmpty
        }

        // First responder management
        if isFirstResponder && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFirstResponder && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    @available(iOS 16.0, *)
    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: UITextView,
        context: Context
    ) -> CGSize? {
        let width = proposal.width ?? UIView.layoutFittingExpandedSize.width
        let size = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: max(size.height, 44))
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor

        init(_ parent: RichTextEditor) { self.parent = parent }

        func textViewDidChange(_ textView: UITextView) {
            parent.attributedText = textView.attributedText ?? NSAttributedString()
            if let label = textView.viewWithTag(999) as? UILabel {
                label.isHidden = !textView.text.isEmpty
            }
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isFirstResponder = true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isFirstResponder = false
        }
    }
}
```

### Usage

```swift
struct NotesEditorView: View {
    @State private var text = NSAttributedString()
    @State private var isFocused = false

    var body: some View {
        RichTextEditor(
            attributedText: $text,
            placeholder: "Write something...",
            isFirstResponder: $isFocused
        )
        .frame(minHeight: 100)
    }
}
```

### Gotchas

- **`NSAttributedString` comparison.** The equality check in `updateUIView` is critical -- without it, every keystroke triggers a full re-render loop.
- **First responder management.** Avoid calling `becomeFirstResponder()` unconditionally in `updateUIView` -- it steals focus from other fields.
- **iOS 26 alternative.** `TextEditor` in iOS 26 supports `AttributedString` natively. Prefer it unless you need `NSAttributedString` or delegate-level control.

---

## 3. AVCaptureVideoPreviewLayer Wrapper

Display a live camera preview. The preview layer requires a `UIView` host.

```swift
import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // Session is reference type -- no update needed unless swapping sessions
        if uiView.previewLayer.session !== session {
            uiView.previewLayer.session = session
        }
    }
}

final class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}
```

### Usage

```swift
struct CameraScreen: View {
    @State private var cameraManager = CameraManager()

    var body: some View {
        CameraPreview(session: cameraManager.session)
            .ignoresSafeArea()
            .task { await cameraManager.start() }
    }
}
```

### Gotchas

- **Use a custom UIView subclass with `layerClass`.** Overriding `layerClass` avoids adding a sublayer and ensures the preview layer resizes automatically with the view.
- **Session management belongs outside the representable.** Create and manage `AVCaptureSession` in a separate model. The representable only displays it.
- **Orientation.** Set `previewLayer.connection?.videoRotationAngle` if supporting device rotation.

---

## 4. PHPickerViewController Wrapper

Multi-select photo picker that loads selected images asynchronously.

```swift
import SwiftUI
import PhotosUI

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    var selectionLimit: Int = 0  // 0 = unlimited
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = selectionLimit
        config.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // Nothing to update -- configuration is immutable after creation
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) { self.parent = parent }

        func picker(
            _ picker: PHPickerViewController,
            didFinishPicking results: [PHPickerResult]
        ) {
            parent.dismiss()

            guard !results.isEmpty else { return }

            Task { @MainActor in
                var images: [UIImage] = []
                for result in results {
                    if let image = await loadImage(from: result.itemProvider) {
                        images.append(image)
                    }
                }
                parent.selectedImages = images
            }
        }

        private func loadImage(from provider: NSItemProvider) async -> UIImage? {
            await withCheckedContinuation { continuation in
                if provider.canLoadObject(ofClass: UIImage.self) {
                    provider.loadObject(ofClass: UIImage.self) { image, _ in
                        continuation.resume(returning: image as? UIImage)
                    }
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
```

### Usage

```swift
struct ImagePickerDemo: View {
    @State private var images: [UIImage] = []
    @State private var showPicker = false

    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(images.indices, id: \.self) { i in
                        Image(uiImage: images[i])
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(.rect(cornerRadius: 8))
                    }
                }
            }
            Button("Pick Photos") { showPicker = true }
        }
        .sheet(isPresented: $showPicker) {
            PhotoPicker(selectedImages: $images, selectionLimit: 5)
        }
    }
}
```

### Gotchas

- **Always dismiss in the delegate.** `picker(_:didFinishPicking:)` is called for both selection and cancellation (with empty results). Dismiss in both cases.
- **Async image loading.** `NSItemProvider.loadObject` is completion-based. Wrap in `withCheckedContinuation` for async/await usage. Load images after dismissal to avoid blocking the picker UI.
- **iOS 17 alternative.** `PhotosUI.PhotosPicker` is a native SwiftUI view. Prefer it unless you need custom picker UI or advanced filtering.

---

## 5. MFMailComposeViewController Wrapper

Present the system email composer with pre-filled fields and handle the result.

```swift
import SwiftUI
import MessageUI

struct MailComposer: UIViewControllerRepresentable {
    let subject: String
    let recipients: [String]
    let body: String
    var isHTML: Bool = false
    var onResult: ((MFMailComposeResult) -> Void)?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setSubject(subject)
        controller.setToRecipients(recipients)
        controller.setMessageBody(body, isHTML: isHTML)
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        // Cannot update mail compose after presentation
    }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposer

        init(_ parent: MailComposer) { self.parent = parent }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            parent.onResult?(result)
            parent.dismiss()
        }
    }
}
```

### Usage

```swift
struct FeedbackView: View {
    @State private var showMail = false

    var body: some View {
        Button("Send Feedback") {
            guard MFMailComposeViewController.canSendMail() else { return }
            showMail = true
        }
        .sheet(isPresented: $showMail) {
            MailComposer(
                subject: "App Feedback",
                recipients: ["support@example.com"],
                body: "I have feedback about..."
            ) { result in
                print("Mail result: \(result.rawValue)")
            }
        }
    }
}
```

### Gotchas

- **Check `canSendMail()` before presenting.** If it returns `false`, do not display `MFMailComposeViewController`; show fallback UI or disable the mail action.
- **Cannot update after presentation.** `updateUIViewController` is intentionally empty -- the mail compose API does not support changing fields after the controller is shown.
- **The delegate protocol name is `MFMailComposeViewControllerDelegate`**, not `MFMailComposeDelegate`.

---

## 6. UIActivityViewController Wrapper (Share Sheet)

Present the system share sheet. This is a `UIViewControllerRepresentable` because `UIActivityViewController` is a controller, not a view.

```swift
import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var activities: [UIActivity]? = nil
    var excludedTypes: [UIActivity.ActivityType]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: activities
        )
        controller.excludedActivityTypes = excludedTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Cannot update after presentation
    }
}
```

### Usage

```swift
struct ContentView: View {
    @State private var showShare = false

    var body: some View {
        Button("Share") { showShare = true }
            .sheet(isPresented: $showShare) {
                ShareSheet(items: ["Check out this app!", URL(string: "https://example.com")!])
                    .presentationDetents([.medium])
            }
    }
}
```

### Gotchas

- **Present via `.sheet`.** Do not try to use `UIActivityViewController` as an inline view -- it is a modal controller.
- **iPad requires `popoverPresentationController`.** When using on iPad outside of `.sheet`, set the source view/rect on the popover controller. SwiftUI's `.sheet` handles this automatically.
- **iOS 16+ alternative.** `ShareLink` is a native SwiftUI view for Transferable items. Prefer it for simple sharing.

---

## 7. UISearchBar Wrapper

Wrap `UISearchBar` with delegate-based callbacks, debounce support, and cancel button handling.

```swift
import SwiftUI
import Combine

struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String = "Search"
    var onSearch: ((String) -> Void)?
    var onCancel: (() -> Void)?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.delegate = context.coordinator
        searchBar.placeholder = placeholder
        searchBar.searchBarStyle = .minimal
        searchBar.autocapitalizationType = .none
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    final class Coordinator: NSObject, UISearchBarDelegate {
        var parent: SearchBar
        private var debounceTask: Task<Void, Never>?

        init(_ parent: SearchBar) { self.parent = parent }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            parent.text = searchText
            searchBar.showsCancelButton = !searchText.isEmpty

            // Debounce search
            debounceTask?.cancel()
            debounceTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                parent.onSearch?(searchText)
            }
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            debounceTask?.cancel()
            parent.onSearch?(parent.text)
            searchBar.resignFirstResponder()
        }

        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            parent.text = ""
            parent.onCancel?()
            searchBar.resignFirstResponder()
            searchBar.showsCancelButton = false
        }
    }
}
```

### Usage

```swift
struct SearchableList: View {
    @State private var query = ""
    @State private var results: [String] = []

    var body: some View {
        VStack(spacing: 0) {
            SearchBar(text: $query, placeholder: "Search items") { text in
                results = performSearch(text)
            }
            List(results, id: \.self) { Text($0) }
        }
    }
}
```

### Gotchas

- **Native `.searchable` modifier.** Prefer SwiftUI's `.searchable(text:)` modifier for standard search patterns. Use this wrapper only when you need precise control over search bar appearance or delegate timing.
- **Debounce with `Task.sleep`.** Cancel the previous task before starting a new one to debounce. `Combine` is not needed.
- **Cancel button state.** Toggle `showsCancelButton` in the delegate, not in `updateUIView`, to avoid layout jumps.

---

## 8. PDFView Wrapper (PDFKit)

Display PDF documents in SwiftUI using `PDFView` from PDFKit. Supports loading from URL, Data, or file path, with configurable display mode and auto-scaling.

```swift
import SwiftUI
import PDFKit

struct PDFViewer: UIViewRepresentable {
    let document: PDFDocument?
    var displayMode: PDFDisplayMode = .singlePageContinuous
    var autoScales: Bool = true
    var displayDirection: PDFDisplayDirection = .vertical
    var pageShadowsEnabled: Bool = true

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.displayMode = displayMode
        pdfView.displayDirection = displayDirection
        pdfView.autoScales = autoScales
        pdfView.pageShadowsEnabled = pageShadowsEnabled
        pdfView.document = document
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        // Update document if it changed (reference comparison)
        if uiView.document !== document {
            uiView.document = document
        }

        if uiView.displayMode != displayMode {
            uiView.displayMode = displayMode
        }

        if uiView.autoScales != autoScales {
            uiView.autoScales = autoScales
        }
    }
}
```

### Convenience Initializers

```swift
extension PDFViewer {
    /// Load a PDF from a URL (local file or remote).
    init(url: URL, displayMode: PDFDisplayMode = .singlePageContinuous) {
        self.document = PDFDocument(url: url)
        self.displayMode = displayMode
    }

    /// Load a PDF from raw data.
    init(data: Data, displayMode: PDFDisplayMode = .singlePageContinuous) {
        self.document = PDFDocument(data: data)
        self.displayMode = displayMode
    }
}
```

### Usage

```swift
struct DocumentView: View {
    let pdfURL: URL

    var body: some View {
        PDFViewer(url: pdfURL)
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Document")
            .navigationBarTitleDisplayMode(.inline)
    }
}
```

### With Async Loading

```swift
struct RemotePDFView: View {
    let url: URL
    @State private var document: PDFDocument?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let document {
                PDFViewer(document: document)
            } else if isLoading {
                ProgressView("Loading PDF...")
            } else if let errorMessage {
                ContentUnavailableView(
                    "Could Not Load PDF",
                    systemImage: "doc.text.fill",
                    description: Text(errorMessage)
                )
            }
        }
        .task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                document = PDFDocument(data: data)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
```

### PDFView with Page Navigation

```swift
struct NavigablePDFView: UIViewRepresentable {
    let document: PDFDocument?
    @Binding var currentPageIndex: Int

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.displayMode = .singlePageContinuous
        pdfView.autoScales = true
        pdfView.document = document

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document !== document {
            uiView.document = document
        }

        // Navigate to page if binding changed externally
        if let doc = uiView.document,
           let page = doc.page(at: currentPageIndex),
           uiView.currentPage != page {
            uiView.go(to: page)
        }
    }

    static func dismantleUIView(_ uiView: PDFView, coordinator: Coordinator) {
        NotificationCenter.default.removeObserver(coordinator)
    }

    final class Coordinator: NSObject {
        var parent: NavigablePDFView

        init(_ parent: NavigablePDFView) { self.parent = parent }

        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let currentPage = pdfView.currentPage,
                  let document = pdfView.document else { return }
            let index = document.index(for: currentPage)
            if parent.currentPageIndex != index {
                parent.currentPageIndex = index
            }
        }
    }
}
```

### Gotchas

- **`PDFView` inherits from `UIView`.** Use `UIViewRepresentable`, not `UIViewControllerRepresentable`.
- **Document is a reference type.** Use `!==` for identity comparison in `updateUIView` to avoid unnecessary reloads.
- **Page change notifications.** Use `NotificationCenter` with `.PDFViewPageChanged` -- `PDFView` does not use a delegate pattern for page changes.
- **Remove observers in `dismantleUIView`.** Failing to remove `NotificationCenter` observers causes crashes after the view is removed.
- **`autoScales`** fits the PDF to the view width. Disable it if you want the user to start at a specific zoom level.
- **Thread safety.** `PDFDocument` loading can be expensive. Load asynchronously and assign on the main thread.

> **Docs:** [PDFView](https://sosumi.ai/documentation/pdfkit/pdfview) | [PDFKit](https://sosumi.ai/documentation/pdfkit)

---

## 9. MFMessageComposeViewController Wrapper

Present the system SMS/MMS composer with pre-filled recipients, body, and optional attachments. Companion to Recipe 6 (MFMailComposeViewController).

```swift
import SwiftUI
import MessageUI

struct MessageComposer: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    var attachments: [MessageAttachment] = []
    var onResult: ((MessageComposeResult) -> Void)?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        controller.recipients = recipients
        controller.body = body

        for attachment in attachments {
            controller.addAttachmentData(
                attachment.data,
                typeIdentifier: attachment.typeIdentifier,
                filename: attachment.filename
            )
        }

        return controller
    }

    func updateUIViewController(
        _ uiViewController: MFMessageComposeViewController,
        context: Context
    ) {
        // Cannot update message compose after presentation
    }

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let parent: MessageComposer

        init(_ parent: MessageComposer) { self.parent = parent }

        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            parent.onResult?(result)
            parent.dismiss()
        }
    }
}

struct MessageAttachment {
    let data: Data
    let typeIdentifier: String // UTI, e.g., "public.jpeg"
    let filename: String
}
```

### Usage

```swift
struct InviteView: View {
    @State private var showMessage = false

    var body: some View {
        Button("Send Invite via SMS") {
            guard MFMessageComposeViewController.canSendText() else { return }
            showMessage = true
        }
        .sheet(isPresented: $showMessage) {
            MessageComposer(
                recipients: ["+1234567890"],
                body: "Join me on this app!"
            ) { result in
                switch result {
                case .sent:
                    print("Message sent")
                case .cancelled:
                    print("User cancelled")
                case .failed:
                    print("Message failed")
                @unknown default:
                    break
                }
            }
        }
    }
}
```

### With Image Attachment

```swift
struct SharePhotoView: View {
    @State private var showMessage = false
    let image: UIImage

    var body: some View {
        Button("Send Photo") {
            guard MFMessageComposeViewController.canSendText(),
                  MFMessageComposeViewController.canSendAttachments() else {
                return
            }
            showMessage = true
        }
        .sheet(isPresented: $showMessage) {
            MessageComposer(
                recipients: [],
                body: "Check out this photo!",
                attachments: [
                    MessageAttachment(
                        data: image.jpegData(compressionQuality: 0.8) ?? Data(),
                        typeIdentifier: "public.jpeg",
                        filename: "photo.jpg"
                    )
                ]
            )
        }
    }
}
```

### Gotchas

- **Check `canSendText()` before presenting.** If it returns `false`, do not display `MFMessageComposeViewController`; show fallback UI or disable the message action.
- **Check `canSendAttachments()` before adding attachments.** Not all devices or carriers support MMS attachments.
- **The delegate protocol is `MFMessageComposeViewControllerDelegate`**, not `MFMessageComposeDelegate`. It has a single required method.
- **Cannot update after presentation.** Like `MFMailComposeViewController`, the message composer API does not support changing fields after the controller is shown.
- **iMessage vs. SMS.** The controller automatically uses iMessage when available. You cannot force one protocol over the other.
- **Simulator limitation.** `canSendText()` returns `false` on the simulator. Test on a physical device.

> **Docs:** [MFMessageComposeViewController](https://sosumi.ai/documentation/messageui/mfmessagecomposeviewcontroller) | [MFMessageComposeViewControllerDelegate](https://sosumi.ai/documentation/messageui/mfmessagecomposeviewcontrollerdelegate)
