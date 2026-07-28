import SwiftUI
import PhotosUI

/// Finished-piece photo (F7, record-bound): camera (with Simulator seam) or
/// library pick; camera denial is skippable and never blocks the finish.
struct FinishedPhotoSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let chartId: UUID

    @State private var showCameraPicker = false
    @State private var showSynthetic = false
    @State private var syntheticImage: UIImage?
    @State private var cameraDenied = false
    @State private var pickedItem: PhotosPickerItem?
    @State private var showLibraryPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.ScreenBackground()
                VStack(spacing: 22) {
                    Image(systemName: "camera.aperture")
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.threadRed)
                        .padding(.top, 32)

                    Text("Snap your finished piece")
                        .font(Theme.titleFont(24))
                        .foregroundStyle(Theme.ink)

                    Text("It stays on this device and shows on the chart and its result card.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.inkSecondary)
                        .padding(.horizontal, 32)

                    if cameraDenied {
                        VStack(spacing: 8) {
                            Text("Camera is off. You can still choose a photo from your library.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Theme.inkSecondary)
                            Button("Choose Photo") {
                                cameraDenied = false
                                showLibraryPicker = true
                            }
                            .buttonStyle(Theme.SecondaryButtonStyle())
                            .padding(.horizontal, 48)
                        }
                    }

                    Button("Take photo") {
                        Task {
                            let outcome = await CameraCapture.requestAccessThenRoute()
                            switch outcome {
                            case .presentPicker:
                                showCameraPicker = true
                            case .synthetic(let image):
                                syntheticImage = image
                                showSynthetic = true
                            case .denied, .restricted:
                                cameraDenied = true
                            }
                        }
                    }
                    .buttonStyle(Theme.PrimaryButtonStyle())
                    .padding(.horizontal, 40)

                    Button("Choose from library") {
                        showLibraryPicker = true
                    }
                    .buttonStyle(Theme.SecondaryButtonStyle())
                    .padding(.horizontal, 40)

                    Button("Skip for now") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.inkSecondary)
                    .frame(minHeight: 44)

                    Spacer()
                }
            }
            .navigationTitle("Finished photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showCameraPicker) {
                CameraPickerSheet { image in
                    showCameraPicker = false
                    bind(image)
                } onCancel: {
                    showCameraPicker = false
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showSynthetic) {
                syntheticConfirm
            }
            .photosPicker(isPresented: $showLibraryPicker, selection: $pickedItem, matching: .images)
            .onChange(of: pickedItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        bind(image)
                    }
                    pickedItem = nil
                }
            }
        }
    }

    private var syntheticConfirm: some View {
        NavigationStack {
            ZStack {
                Theme.ScreenBackground()
                VStack(spacing: 20) {
                    if let syntheticImage {
                        Image(uiImage: syntheticImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal, 20)
                    }
                    Button("Use this photo") {
                        showSynthetic = false
                        if let syntheticImage {
                            bind(syntheticImage)
                        }
                    }
                    .buttonStyle(Theme.PrimaryButtonStyle())
                    .padding(.horizontal, 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSynthetic = false }
                }
            }
        }
    }

    private func bind(_ image: UIImage) {
        if let path = store.saveSandboxPhoto(image, prefix: "finished") {
            store.setFinishedPhoto(chartId: chartId, relativePath: path)
        }
        dismiss()
    }
}
