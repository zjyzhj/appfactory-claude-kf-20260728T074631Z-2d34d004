import SwiftUI
import PhotosUI

/// create_wizard — source → tune → preview → save (F2/F3).
/// Camera is JIT + record-bound; Simulator uses the deterministic capture seam.
struct CreateWizardView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum Step {
        case pickSource
        case tuning
        case saving
    }

    enum SourceKind {
        case photo(UIImage)
        case blank
    }

    @State private var step: Step = .pickSource
    @State private var sourcePhoto: UIImage?
    @State private var sourceKind: SourceKind = .blank

    // Tuning.
    @State private var widthCells: Double = 80
    @State private var maxColors: Double = 12
    @State private var symbolMode: SymbolMode = .symbols
    @State private var preview: ChartQuantizer.Result?
    @State private var previewTask: Task<Void, Never>?

    // Permission / denial states.
    @State private var deniedCamera = false
    @State private var deniedPhotoRead = false
    @State private var showCameraPicker = false
    @State private var showSyntheticCapture = false
    @State private var syntheticImage: UIImage?
    @State private var photoPickerItem: PhotosPickerItem?

    // Save.
    @State private var showNaming = false
    @State private var chartTitle = ""

    enum SymbolMode: String, CaseIterable {
        case symbols = "Symbols"
        case color = "Color"
        case both = "Both"
    }

    private var heightCells: Int {
        // Keep the photo's aspect: height follows width slider within 30–200.
        guard let photo = sourcePhoto, photo.size.width > 0 else {
            return Int(widthCells)
        }
        let ratio = photo.size.height / photo.size.width
        return min(200, max(30, Int((widthCells * ratio).rounded())))
    }

    var body: some View {
        ZStack {
            Theme.ScreenBackground()
            switch step {
            case .pickSource:
                pickSourceView
            case .tuning:
                tuningView
            case .saving:
                savingView
            }
        }
        .navigationTitle("New chart")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCameraPicker) {
            CameraPickerSheet { image in
                showCameraPicker = false
                beginTuning(with: image)
            } onCancel: {
                showCameraPicker = false
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showSyntheticCapture) {
            syntheticCaptureSheet
        }
        .photosPicker(
            isPresented: $showSystemPhotoPicker,
            selection: $photoPickerItem,
            matching: .images
        )
        .sheet(isPresented: $showNaming) {
            namingSheet
                .presentationDetents([.medium])
        }
        .onChange(of: photoPickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    beginTuning(with: image)
                } else {
                    // Picker failed — recovery stays in-app (denied_photo).
                    deniedPhotoRead = true
                }
                photoPickerItem = nil
            }
        }
    }

    // MARK: - pick_source

    private var pickSourceView: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Start a new pattern")
                    .font(Theme.titleFont(26))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                if deniedCamera {
                    denialCard(
                        title: "Camera is off.",
                        message: "You can still choose a photo from your library.",
                        primaryLabel: "Choose Photo",
                        primaryAction: { deniedCamera = false; openPhotoPicker() },
                        secondaryLabel: "Not now",
                        secondaryAction: { deniedCamera = false }
                    )
                }

                if deniedPhotoRead {
                    denialCard(
                        title: "Photo access is off.",
                        message: "You can start from a blank grid instead.",
                        primaryLabel: "Start Blank",
                        primaryAction: { deniedPhotoRead = false; beginBlank() },
                        secondaryLabel: "Retry",
                        secondaryAction: { deniedPhotoRead = false; openPhotoPicker() }
                    )
                }

                sourceCard(
                    icon: "camera.fill",
                    title: "Take a photo",
                    subtitle: "Camera stays on this device.",
                    action: takePhoto
                )

                PhotosPicker(selection: $photoPickerItem, matching: .images, photoLibrary: .shared()) {
                    sourceCardLabel(icon: "photo.on.rectangle", title: "Choose from library", subtitle: "Pick a photo to chart.")
                }
                .buttonStyle(.plain)

                sourceCard(
                    icon: "square.grid.3x3",
                    title: "Start from a blank grid",
                    subtitle: "Draw every stitch yourself.",
                    action: beginBlank
                )

                Text("Photos never leave this device.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
                    .padding(.top, 8)

                Spacer(minLength: 24)
            }
        }
    }

    private func sourceCard(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            sourceCardLabel(icon: icon, title: title, subtitle: subtitle)
        }
        .buttonStyle(.plain)
    }

    private func sourceCardLabel(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.threadRed.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.threadRed)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Theme.headlineSerif(18))
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Theme.inkSecondary)
        }
        .padding(16)
        .atelierCard()
        .padding(.horizontal, 20)
    }

    private func denialCard(title: String, message: String, primaryLabel: String, primaryAction: @escaping () -> Void, secondaryLabel: String, secondaryAction: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(Theme.headlineSerif(17))
                .foregroundStyle(Theme.ink)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
            HStack(spacing: 12) {
                Button(primaryLabel, action: primaryAction)
                    .buttonStyle(Theme.SecondaryButtonStyle())
                Button(secondaryLabel, action: secondaryAction)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.inkSecondary)
                    .frame(minHeight: 44)
            }
        }
        .padding(16)
        .atelierCard()
        .padding(.horizontal, 20)
    }

    // MARK: - tuning / previewing

    private var tuningView: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Source photo preview (create_source_photo slot, 40–60% viewport).
                if let photo = sourcePhoto {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 240)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(alignment: .topLeading) {
                            Text("Source")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(.black.opacity(0.55)))
                                .padding(10)
                        }
                        .padding(.horizontal, 20)
                } else {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.card)
                        .frame(height: 90)
                        .overlay {
                            Label("Blank grid — draw it yourself", systemImage: "square.grid.3x3")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Theme.inkSecondary)
                        }
                        .padding(.horizontal, 20)
                }

                StitchDivider()
                    .padding(.horizontal, 40)

                // Live chart preview.
                if let preview, let chart = previewChart(from: preview) {
                    GridCanvasView(
                        chart: chart,
                        mode: .display,
                        showSymbols: symbolMode != .color,
                        reduceMotion: reduceMotion
                    )
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Theme.hairline, lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        Text("Chart preview")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(.black.opacity(0.55)))
                            .padding(10)
                    }
                    .padding(.horizontal, 20)

                    Text("\(Int(widthCells)) × \(heightCells) · \(preview.palette.count) colors")
                        .font(Theme.mono(13))
                        .foregroundStyle(Theme.inkSecondary)
                } else {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.card)
                        .frame(height: 280)
                        .overlay {
                            VStack(spacing: 8) {
                                ProgressView()
                                Text("Charting your photo…")
                                    .font(.caption)
                                    .foregroundStyle(Theme.inkSecondary)
                            }
                        }
                        .padding(.horizontal, 20)
                }

                // Controls.
                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Size")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Text("\(Int(widthCells)) cells across")
                                .font(Theme.mono(12))
                                .foregroundStyle(Theme.threadRed)
                        }
                        Slider(value: $widthCells, in: 30...160, step: 10)
                            .tint(Theme.threadRed)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Colors")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Text("up to \(Int(maxColors))")
                                .font(Theme.mono(12))
                                .foregroundStyle(Theme.threadRed)
                        }
                        Slider(value: $maxColors, in: 4...30, step: 2)
                            .tint(Theme.threadRed)
                    }

                    Picker("Preview style", selection: $symbolMode) {
                        ForEach(SymbolMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(16)
                .atelierCard()
                .padding(.horizontal, 20)
                .onChange(of: widthCells) { _, _ in schedulePreview() }
                .onChange(of: maxColors) { _, _ in schedulePreview() }

                Button {
                    chartTitle = suggestedTitle()
                    showNaming = true
                } label: {
                    Label("Looks good, continue", systemImage: "checkmark")
                }
                .buttonStyle(Theme.PrimaryButtonStyle())
                .disabled(preview == nil)
                .padding(.horizontal, 20)

                Button("Start over") {
                    step = .pickSource
                    sourcePhoto = nil
                    preview = nil
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.inkSecondary)
                .frame(minHeight: 44)

                Spacer(minLength: 24)
            }
            .padding(.top, 12)
        }
        .onAppear(perform: schedulePreview)
    }

    private var savingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Saving your chart…")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Camera & capture seam

    private func takePhoto() {
        Task {
            let outcome = await CameraCapture.requestAccessThenRoute()
            switch outcome {
            case .presentPicker:
                showCameraPicker = true
            case .synthetic(let image):
                syntheticImage = image
                showSyntheticCapture = true
            case .denied, .restricted:
                deniedCamera = true
            }
        }
    }

    private var syntheticCaptureSheet: some View {
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
                    Text("Captured photo")
                        .font(Theme.headlineSerif(18))
                        .foregroundStyle(Theme.ink)
                    Button("Use this photo") {
                        showSyntheticCapture = false
                        if let syntheticImage {
                            beginTuning(with: syntheticImage)
                        }
                    }
                    .buttonStyle(Theme.PrimaryButtonStyle())
                    .padding(.horizontal, 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSyntheticCapture = false }
                }
            }
        }
    }

    private func openPhotoPicker() {
        // PhotosPicker is presented via the binding below.
        photoPickerItem = nil
        showSystemPhotoPicker = true
    }

    @State private var showSystemPhotoPicker = false

    // MARK: - Naming & save

    private var namingSheet: some View {
        NavigationStack {
            ZStack {
                Theme.ScreenBackground()
                VStack(spacing: 20) {
                    Text("Name your chart")
                        .font(Theme.titleFont(24))
                        .foregroundStyle(Theme.ink)
                    TextField("Chart name", text: $chartTitle)
                        .font(.body)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Theme.card)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Theme.hairline, lineWidth: 1)
                        )
                        .padding(.horizontal, 24)
                        .submitLabel(.done)
                        .onSubmit(saveChart)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                }
                            }
                        }
                    Button("Save chart", action: saveChart)
                        .buttonStyle(Theme.PrimaryButtonStyle())
                        .disabled(chartTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                        .padding(.horizontal, 24)
                    Spacer()
                }
                .padding(.top, 24)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showNaming = false }
                }
            }
        }
    }

    private func suggestedTitle() -> String {
        switch sourceKind {
        case .photo: return "Photo chart"
        case .blank: return "Blank chart"
        }
    }

    private func saveChart() {
        guard let preview else { return }
        let trimmed = chartTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        showNaming = false
        step = .saving

        let w = Int(widthCells)
        let h = heightCells
        var photoPath: String?
        if let photo = sourcePhoto {
            photoPath = store.saveSandboxPhoto(photo, prefix: "source")
        }

        let chart = Chart(
            title: trimmed,
            sourcePhotoPath: photoPath,
            widthCells: w,
            heightCells: h,
            maxColors: Int(maxColors),
            cells: preview.cells,
            palette: preview.palette,
            status: .draft
        )
        let saved = store.addChart(chart)
        Haptics.success()

        // Reset wizard, then open the new chart's detail.
        step = .pickSource
        sourcePhoto = nil
        self.preview = nil
        store.chartIdToOpen = saved.id
        store.selectedTab = .charts
    }

    // MARK: - Preview quantization (debounced, on-device)

    private func schedulePreview() {
        previewTask?.cancel()
        let photo = sourcePhoto
        let w = Int(widthCells)
        let colors = Int(maxColors)
        let h = heightCells
        previewTask = Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }
            let result: ChartQuantizer.Result
            if let photo {
                result = ChartQuantizer.quantize(image: photo, widthCells: w, heightCells: h, maxColors: colors)
            } else {
                result = ChartQuantizer.blank(widthCells: w, heightCells: h)
            }
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.preview = result
            }
        }
    }

    private func previewChart(from result: ChartQuantizer.Result) -> Chart? {
        Chart(
            title: "preview",
            widthCells: Int(widthCells),
            heightCells: heightCells,
            maxColors: Int(maxColors),
            cells: result.cells,
            palette: result.palette
        )
    }

    private func beginTuning(with image: UIImage) {
        sourcePhoto = image
        sourceKind = .photo(image)
        preview = nil
        step = .tuning
        schedulePreview()
    }

    private func beginBlank() {
        sourcePhoto = nil
        sourceKind = .blank
        preview = nil
        step = .tuning
        schedulePreview()
    }
}
