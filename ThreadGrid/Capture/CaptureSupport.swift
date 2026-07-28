import Foundation
import AVFoundation
import Photos
import SwiftUI
import UIKit

/// Record-bound, just-in-time camera access (checklist §12). The capture task
/// is named by the caller (chart source vs finished piece) so denial copy can
/// name what was interrupted. Denial recovers in-app — never a Settings jump.
enum CameraCapture {

    enum Outcome {
        /// Hardware camera is available and permission granted — present the picker.
        case presentPicker
        /// Permission granted but no camera hardware (Simulator) — deterministic seam.
        case synthetic(UIImage)
        case denied
        case restricted
    }

    static var hardwareAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    /// Deterministic capture seam for QA: `-syntheticCapture` launch argument or
    /// `THREADGRID_SYNTHETIC_CAPTURE=1` forces the synthetic provider even when a
    /// (virtual) camera exists, so Simulator runs stay deterministic (checklist §12).
    static var forceSyntheticCapture: Bool {
        ProcessInfo.processInfo.arguments.contains("-syntheticCapture")
            || ProcessInfo.processInfo.environment["THREADGRID_SYNTHETIC_CAPTURE"] == "1"
    }

    /// Requests access only after an explicit capture action, then routes to the
    /// real picker or the deterministic synthetic seam.
    static func requestAccessThenRoute() async -> Outcome {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return routeAfterGrant()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            return granted ? routeAfterGrant() : .denied
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .denied
        }
    }

    private static func routeAfterGrant() -> Outcome {
        if hardwareAvailable && !forceSyntheticCapture {
            return .presentPicker
        }
        return .synthetic(SamplePhotoFactory.makeStitchSample())
    }
}

/// System camera picker (real devices only).
struct CameraPickerSheet: UIViewControllerRepresentable {
    var onCapture: (UIImage) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerSheet
        init(_ parent: CameraPickerSheet) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            } else {
                parent.onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }
    }
}

/// Photo-library *write* (JIT, addOnly) with friendly denial recovery handled
/// by the caller (chart_export denied_photo_write → Share / Retry, no Settings).
enum PhotoLibraryWriter {

    enum WriteOutcome {
        case saved
        case denied
        case failed
    }

    static func authorizationStatus() -> PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .addOnly)
    }

    static func saveToPhotos(_ image: UIImage) async -> WriteOutcome {
        var status = authorizationStatus()
        if status == .notDetermined {
            status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        }
        switch status {
        case .authorized, .limited:
            break
        case .denied, .restricted:
            return .denied
        default:
            return .failed
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            return .saved
        } catch {
            print("[ThreadGrid] photo save failed: \(error)")
            return .failed
        }
    }
}
