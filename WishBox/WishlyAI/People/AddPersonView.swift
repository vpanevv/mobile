import SwiftUI
import SwiftData
import UIKit

// MARK: - AddPersonView

struct AddPersonView: View {
    // When non-nil we're editing an existing person
    var editingPerson: Person? = nil
    var onDismiss: (() -> Void)? = nil

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    // Entry mode
    @State private var entryMode: EntryMode = .manual
    @State private var showContactPicker = false
    // Staging area: CNContactPickerVC auto-dismisses itself, so we capture the result
    // here and apply it in onDismiss (never call showContactPicker = false in the callback)
    @State private var pendingContact: (name: String, day: Int?, month: Int?)? = nil

    // Fields
    @State private var name     = ""
    @State private var occasion = HolidayType.birthday
    @State private var day      = 1
    @State private var month    = 1

    // Occasion dropdown
    @State private var occasionExpanded = false

    // Feedback
    @State private var isSaving             = false
    @State private var showNotifDeniedNote  = false
    @State private var nameError            = false

    // ── Days per month ──────────────────────────────────────────────
    private var daysInSelectedMonth: Int {
        // Use a non-leap year as baseline; Feb 29 is handled separately
        let comps = DateComponents(year: 2024, month: month)  // 2024 is a leap year
        return Calendar.current.range(of: .day, in: .month, for: Calendar.current.date(from: comps)!)?.count ?? 31
    }

    private static let months = Calendar.current.monthSymbols   // ["January", ...]

    enum EntryMode: String, CaseIterable {
        case manual   = "Type Manually"
        case contacts = "From Contacts"
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Handle ──────────────────────────────────────────
                Capsule()
                    .fill(Color.primary.opacity(0.18))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {

                        // Title
                        Text(editingPerson == nil ? "Add Someone" : "Edit Person")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 24)

                        // ── Entry mode picker (hidden when editing) ──
                        if editingPerson == nil {
                            entryModePicker
                        }

                        // ── Name field ───────────────────────────────
                        VStack(alignment: .leading, spacing: 6) {
                            sectionLabel("NAME")
                            TextField("e.g. Maria", text: $name)
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(nameError ? Color.red.opacity(0.6) : Color.primary.opacity(0.10), lineWidth: 1)
                                )
                                .onChange(of: name) { _, _ in nameError = false }
                        }
                        .padding(.horizontal, 24)

                        // ── Occasion picker (dropdown) ───────────────
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel("OCCASION")
                            occasionDropdown
                        }
                        .padding(.horizontal, 24)

                        // ── Date picker ──────────────────────────────
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel("DATE (day & month)")
                            datePicker
                        }
                        .padding(.horizontal, 24)

                        // ── Notification denied note ─────────────────
                        if showNotifDeniedNote {
                            notifDeniedBanner
                                .padding(.horizontal, 24)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // ── Save button ──────────────────────────────
                        saveButton
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                    }
                }
            }
        }
        .onAppear { prefill() }
        .presentationDetents([.large])
        .presentationCornerRadius(32)
        .presentationDragIndicator(.hidden)
        // CNContactPickerViewController auto-dismisses itself at the UIKit level when a
        // contact is tapped. We must NOT call showContactPicker = false inside the callback —
        // doing so confuses SwiftUI into collapsing the whole sheet stack.
        // Instead: store the result in pendingContact, then apply it in onDismiss.
        .sheet(isPresented: $showContactPicker, onDismiss: {
            guard let contact = pendingContact else { return }
            name = contact.name
            if let d = contact.day   { day   = d }
            if let m = contact.month { month = m }
            entryMode = .manual
            pendingContact = nil
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }) {
            ContactPicker { pickedName, pickedDay, pickedMonth in
                // Just stage — do NOT touch showContactPicker here
                pendingContact = (pickedName, pickedDay, pickedMonth)
            }
        }
    }

    // MARK: - Subviews

    private var entryModePicker: some View {
        HStack(spacing: 0) {
            ForEach(EntryMode.allCases, id: \.self) { mode in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if mode == .contacts {
                        showContactPicker = true
                    } else {
                        entryMode = mode
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(entryMode == mode ? Color(hex: 0xc084fc) : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            entryMode == mode
                                ? Color(hex: 0xc084fc).opacity(0.12)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.primary.opacity(0.08), lineWidth: 1))
        .padding(.horizontal, 24)
    }

    private var occasionDropdown: some View {
        VStack(spacing: 0) {
            // ── Trigger row ─────────────────────────────────────────
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                    occasionExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Text(occasion.emoji)
                        .font(.system(size: 18))
                    Text(occasion.rawValue)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: 0xc084fc).opacity(0.7))
                        .rotationEffect(.degrees(occasionExpanded ? -180 : 0))
                        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: occasionExpanded)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // ── Option list ─────────────────────────────────────────
            if occasionExpanded {
                Divider()
                    .background(Color(hex: 0xc084fc).opacity(0.15))

                VStack(spacing: 0) {
                    ForEach(Array(HolidayType.allCases.enumerated()), id: \.element.id) { idx, occ in
                        let isSelected = occ == occasion
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                                occasion = occ
                                occasionExpanded = false
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Text(occ.emoji)
                                    .font(.system(size: 16))
                                Text(occ.rawValue)
                                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular, design: .rounded))
                                    .foregroundStyle(isSelected ? Color(hex: 0xc084fc) : .primary)
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Color(hex: 0xc084fc))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(isSelected ? Color(hex: 0xc084fc).opacity(0.07) : Color.clear)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if idx < HolidayType.allCases.count - 1 {
                            Divider()
                                .background(Color.primary.opacity(0.05))
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: 0xc084fc).opacity(occasionExpanded ? 0.50 : 0.25),
                            Color(hex: 0xa78bfa).opacity(occasionExpanded ? 0.30 : 0.12)
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color(hex: 0xc084fc).opacity(occasionExpanded ? 0.12 : 0.05), radius: occasionExpanded ? 16 : 8)
    }

    private var datePicker: some View {
        HStack(spacing: 12) {
            // Day wheel
            VStack(alignment: .leading, spacing: 6) {
                Text("DAY")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                Picker("Day", selection: $day) {
                    ForEach(1...daysInSelectedMonth, id: \.self) { d in
                        Text("\(d)").tag(d)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            // Month wheel
            VStack(alignment: .leading, spacing: 6) {
                Text("MONTH")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                Picker("Month", selection: $month) {
                    ForEach(1...12, id: \.self) { m in
                        Text(AddPersonView.months[m - 1]).tag(m)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        // Clamp day if switching to a shorter month
        .onChange(of: month) { _, _ in
            let max = daysInSelectedMonth
            if day > max { day = max }
        }
    }

    private var saveButton: some View {
        Button {
            save()
        } label: {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView().tint(.white).scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                    Text(editingPerson == nil ? "Save Reminder" : "Update")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0x9333ea), Color(hex: 0xc084fc)],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color(hex: 0xc084fc).opacity(0.40), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
    }

    private var notifDeniedBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "bell.slash.fill")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Reminders disabled")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text("Enable notifications in Settings to get reminded on this day.")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
            .tracking(1.5)
    }

    // MARK: - Logic

    private func prefill() {
        guard let p = editingPerson else { return }
        name     = p.name
        occasion = p.occasion
        day      = p.day
        month    = p.month
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            withAnimation { nameError = true }
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        isSaving = true

        Task {
            let granted = await ReminderManager.shared.requestAuthorizationIfNeeded()

            if let existing = editingPerson {
                // Cancel old notification before updating
                ReminderManager.shared.cancelReminder(for: existing)
                existing.name             = name.trimmingCharacters(in: .whitespaces)
                existing.occasionRawValue = occasion.rawValue
                existing.day              = day
                existing.month            = month
                if granted { ReminderManager.shared.scheduleReminder(for: existing) }
            } else {
                let person = Person(
                    name:     name.trimmingCharacters(in: .whitespaces),
                    occasion: occasion,
                    day:      day,
                    month:    month
                )
                context.insert(person)
                if granted { ReminderManager.shared.scheduleReminder(for: person) }
            }

            UINotificationFeedbackGenerator().notificationOccurred(.success)
            isSaving = false

            if !granted {
                withAnimation { showNotifDeniedNote = true }
                try? await Task.sleep(nanoseconds: 2_500_000_000)
            }

            dismiss()
            onDismiss?()
        }
    }
}
