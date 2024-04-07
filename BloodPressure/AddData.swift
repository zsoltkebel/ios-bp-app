//
//  AddData.swift
//  BloodPressure
//
//  Created by Zsolt Kébel on 08/02/2024.
//

import SwiftUI
import Combine

enum Options: String {
    case now, custom
}

struct AddData: View {
    enum FocusedField: Int {
        case sys, dia, heartRate
    }
    
    @Environment(\.dismiss) var dismiss
    
    @State private var date: Date = .now.minutePrecision()!  // date and time of the measurement
    @State private var systolic: Int?
    @State private var diastolic: Int?
    @State private var heartRate: Int?
    
    private var healtKitManager = HealthKitManager()
    
    // the toggle for showing "Health access is denied open Settings" to enable alert
    @State private var showingAccessDeniedAlert = false
    
    @FocusState private var focusedField: FocusedField?
    
    init(sys: Int? = nil, dia: Int? = nil, hr: Int? = nil) {
        self._systolic = State(initialValue: sys)
        self._diastolic = State(initialValue: dia)
        self._heartRate = State(initialValue: hr)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    // Date & Time section
                    Section {
                        NavigationLink {
                            Form {
                                DatePicker("Date & Time", selection: $date, in: Date.distantPast...Date.now)
                                    .datePickerStyle(.graphical)
                            }
                            .navigationTitle("Date & Time")
                            .toolbarTitleDisplayMode(.inline)
                        } label: {
                            Text(date.relativeString())
                                .fontWeight(.bold)
                                .padding(.customVertical)
                        }
                    } header: {
                        Text("Date & Time")
                    }
                    
                    // Blood Pressure input section
                    Section {
                        HStack {
                            SimpleNumberInput(text: "Systolic", value: $systolic)
                                .focused($focusedField, equals: .sys)
                            Divider()
                                .padding([.vertical], -4)
                                .padding([.horizontal], 10)
                            SimpleNumberInput(text: "Diastolic", value: $diastolic)
                                .focused($focusedField, equals: .dia)
                        }
                    } header: {
                        Text("Blood Pressure")
                    }
                    
                    // Heart Rate input section
                    Section {
                        SimpleNumberInput(text: "BPM", value: $heartRate)
                            .focused($focusedField, equals: .heartRate)
                    } header: {
                        Text("Heart Rate")
                    }
                }
                .fontDesign(.rounded)
            }
            .navigationTitle("Add to Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add") {
                        onAddDataPressed()
                    }
                    .disabled(!self.isInputValid())
                }
            })
            .onAppear {
                focusedField = .sys
            }
            .alert(
                "Can't access your Health Data",
                isPresented: $showingAccessDeniedAlert
            ) {
                Button("OK") {
                    // Handle the acknowledgement.
                }
                Button("Open Settings") {
                    // Get the settings URL and open it
                    // Settings url would be URL(string: UIApplication.openSettingsURLString)
                    if let url = URL(string: "App-Prefs:HEALTH&path=SOURCES_ITEM") {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("Go to Settings > Health > Data Accesss & Devices > blood_pressure and click \"Turn On All\"")
            }
            .onChange(of: systolic) {
                if let systolic = systolic {
                    if String(systolic).count >= 3 {
                        focusNextField()
                    }
                }
            }
            .onChange(of: diastolic) {
                if let diastolic = diastolic {
                    if String(diastolic).count >= 2 {
                        focusNextField()
                    }
                }
            }
        }
    }
    
    private func focusNextField() {
        focusedField = focusedField.map {
            FocusedField(rawValue: $0.rawValue + 1) ?? .sys
        }
    }
    
    func isInputValid() -> Bool {
        let sysValid = systolic != nil && 40 <= systolic! && systolic! <= 300
        let diaValid = diastolic != nil && 30 <= diastolic! && diastolic! <= 200
        let heartRateValid = heartRate != nil && 30 <= heartRate! && heartRate! <= 350
        return sysValid && diaValid && heartRateValid
    }
    
    func onAddDataPressed() {
        healtKitManager.authorizationRequestHealthKit { available, error in
            guard healtKitManager.isSharingAuthorizedForAllSamples() else {
                print("not auhtorised")
                showingAccessDeniedAlert = true
                return
            }
            healtKitManager.save(systolic: systolic!, diastolic: diastolic!, heartRate: heartRate!, date: date) { success, error in
                if success, error == nil {
                    systolic = nil
                    diastolic = nil
                    heartRate = nil
                    clearRelevantNotification()
                    dismiss()
                }
            }
        }
        
    }
    
    func clearRelevantNotification() {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            notifications.forEach { notification in
                let diff = date.timeIntervalSince(notification.date)
                if abs(diff) < 60 * 60 {
                    UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notification.request.identifier])
                }
            }
        }
    }
}

struct SimpleNumberInput: View {
    let text: String
    let value: Binding<Int?>
    
    @FocusState private var focused: Bool
    
    var body: some View {
        HStack {
            Text("\(text)")
                .foregroundStyle(.secondary)
                .fontDesign(.rounded)
            TextField("", value: value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .focused($focused)
                .fontWeight(.bold)
        }
        .padding(.customVertical)
        .onTapGesture(perform: {
            focused = true
        })
    }
}

#Preview {
    AddData(sys: 120, dia: 80)
        .modelContainer(PreviewSampleData.container)
}

extension EdgeInsets {
    static var customVertical = EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)
}
