import SwiftData
import SwiftUI

struct AddCarView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var profile: UserProfile

    @State private var step = 0
    @State private var searchText = ""
    @State private var selectedMake: CarMake?
    @State private var selectedModel = ""
    @State private var selectedYear = Calendar.current.component(.year, from: .now)
    @State private var selectedEngineType: EngineType = .gasoline
    @State private var currentMileage = 0.0
    @State private var trim = ""
    @State private var plateNumber = ""
    @State private var vin = ""
    @State private var photoData: Data?

    private let steps = ["Make", "Model", "Year", "Engine", "Details", "Photo", "Review"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressHeader
                    .padding(.horizontal)
                    .padding(.top, 10)

                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                footer
                    .padding()
                    .background(.bar)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add Car")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(steps[step])
                .font(.title2.bold())
            ProgressView(value: Double(step + 1), total: Double(steps.count))
                .tint(.accentColor)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0:
            searchableMakeList
        case 1:
            searchableModelList
        case 2:
            yearPicker
        case 3:
            engineTypePicker
        case 4:
            detailsForm
        case 5:
            ScrollView {
                CarPhotoPickerView(imageData: $photoData, title: "Car Photo")
                    .padding()
            }
        default:
            review
        }
    }

    private var searchableMakeList: some View {
        List(filteredMakes) { make in
            Button {
                selectedMake = make
                selectedModel = ""
                searchText = ""
                step = 1
                HapticsManager.lightTap()
            } label: {
                HStack {
                    Text(make.name)
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                }
            }
            .foregroundStyle(.primary)
            .listRowBackground(Color.clear)
        }
        .searchable(text: $searchText, prompt: "Search makes")
        .scrollContentBackground(.hidden)
    }

    private var searchableModelList: some View {
        List(filteredModels, id: \.self) { model in
            Button {
                selectedModel = model
                searchText = ""
                step = 2
                HapticsManager.lightTap()
            } label: {
                HStack {
                    Text(model)
                        .font(.headline)
                    Spacer()
                    if selectedModel == model {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.tint)
                    }
                }
            }
            .foregroundStyle(.primary)
            .listRowBackground(Color.clear)
        }
        .searchable(text: $searchText, prompt: "Search models")
        .scrollContentBackground(.hidden)
    }

    private var yearPicker: some View {
        VStack(spacing: 22) {
            Picker("Year", selection: $selectedYear) {
                ForEach((1980...Calendar.current.component(.year, from: .now) + 1).reversed(), id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }
            .pickerStyle(.wheel)

            GlassCardView {
                Label("\(selectedYear) \(selectedMake?.name ?? "") \(selectedModel)", systemImage: "calendar")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
        }
        .padding(.top)
    }

    private var detailsForm: some View {
        Form {
            Section {
                TextField("Current mileage", value: $currentMileage, format: .number)
                    .keyboardType(.decimalPad)
                Picker("Unit", selection: $profile.mileageUnit) {
                    Text("km").tag("km")
                    Text("mi").tag("mi")
                }
                .pickerStyle(.segmented)
            }

            DisclosureGroup("Optional details") {
                TextField("Trim", text: $trim)
                TextField("Plate number", text: $plateNumber)
                    .textInputAutocapitalization(.characters)
                TextField("VIN", text: $vin)
                    .textInputAutocapitalization(.characters)
            }
        }
        .scrollContentBackground(.hidden)
    }

    private var engineTypePicker: some View {
        VStack(spacing: 14) {
            ForEach(EngineType.allCases) { engineType in
                Button {
                    selectedEngineType = engineType
                    HapticsManager.lightTap()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: engineType.symbolName)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(selectedEngineType == engineType ? Color.white : Color.accentColor)
                            .frame(width: 42, height: 42)
                            .background {
                                Circle()
                                    .fill(selectedEngineType == engineType ? Color.accentColor : Color.accentColor.opacity(0.12))
                            }

                        Text(engineType.title)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Spacer()

                        if selectedEngineType == engineType {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.tint)
                                .font(.title3)
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Select \(engineType.title) engine")
            }
        }
        .padding()
    }

    private var review: some View {
        ScrollView {
            VStack(spacing: 16) {
                GlassCardView {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("Ready to Save", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundStyle(.tint)
                        Text("\(selectedYear) \(selectedMake?.name ?? "") \(selectedModel)")
                            .font(.title2.bold())
                        Text("\(currentMileage.formatted(.number.precision(.fractionLength(0)))) \(profile.mileageUnit)")
                            .foregroundStyle(.secondary)
                        Label(selectedEngineType.title, systemImage: selectedEngineType.symbolName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.tint)

                        if !trim.isEmpty || !plateNumber.isEmpty || !vin.isEmpty {
                            Divider()
                            if !trim.isEmpty { Text("Trim: \(trim)") }
                            if !plateNumber.isEmpty { Text("Plate: \(plateNumber)") }
                            if !vin.isEmpty { Text("VIN: \(vin)") }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let validationMessage {
                Text(validationMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .accessibilityLabel(validationMessage)
            }

            HStack(spacing: 12) {
                if step > 0 {
                    Button {
                        step -= 1
                        HapticsManager.lightTap()
                    } label: {
                        Image(systemName: "chevron.left")
                            .frame(width: 42, height: 42)
                    }
                    .buttonStyle(.bordered)
                    .clipShape(Circle())
                    .accessibilityLabel("Previous step")
                }

                Button {
                    if step == steps.count - 1 {
                        saveCar()
                    } else {
                        step += 1
                        HapticsManager.lightTap()
                    }
                } label: {
                    Label(step == steps.count - 1 ? "Save Car" : "Continue", systemImage: step == steps.count - 1 ? "checkmark" : "chevron.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canContinue)
                .accessibilityLabel(step == steps.count - 1 ? "Save car" : "Continue")
            }
        }
    }

    private var filteredMakes: [CarMake] {
        guard !searchText.isEmpty else { return SampleCarData.makes }
        return SampleCarData.makes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredModels: [String] {
        let models = selectedMake?.models ?? []
        guard !searchText.isEmpty else { return models }
        return models.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    private var canContinue: Bool {
        switch step {
        case 0:
            selectedMake != nil
        case 1:
            !selectedModel.isEmpty
        case 4:
            currentMileage >= 0
        default:
            true
        }
    }

    private var validationMessage: String? {
        switch step {
        case 0 where selectedMake == nil:
            "Choose a make to continue."
        case 1 where selectedModel.isEmpty:
            "Choose a model to continue."
        case 4 where currentMileage < 0:
            "Mileage cannot be negative."
        default:
            nil
        }
    }

    private func saveCar() {
        guard let selectedMake else { return }

        let car = Car(
            make: selectedMake.name,
            model: selectedModel,
            year: selectedYear,
            trim: trim.nilIfBlank,
            plateNumber: plateNumber.nilIfBlank,
            vin: vin.nilIfBlank,
            currentMileage: currentMileage,
            mileageUnit: profile.mileageUnit,
            engineType: selectedEngineType,
            photoData: photoData
        )
        car.owner = profile
        profile.cars.append(car)

        do {
            try modelContext.save()
            HapticsManager.success()
            dismiss()
        } catch {
            assertionFailure("Failed to save car: \(error)")
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
