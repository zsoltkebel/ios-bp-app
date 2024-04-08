//
//  AddData.swift
//  BloodPressure
//
//  Created by Zsolt Kébel on 08/04/2024.
//

import AppIntents

struct AddDataIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Blood Pressure Data"
    
    static var description: IntentDescription = "Add Blood Pressure and Heart Rate data measured with external device into the Health app."
    
    @Parameter(title: "Systolic Value (mmHg)")
    var systolic: Int
    
    @Parameter(title: "Diastolic Value (mmHg)")
    var diastolic: Int
    
    @Parameter(title: "Heart Rate (BPM)")
    var heartRate: Int
    
    func perform() async throws -> some ProvidesDialog {
        let m = HealthKitManager()
                
        let success = await withCheckedContinuation { continuation in
            m.save(systolic: systolic, diastolic: diastolic, heartRate: heartRate) { success, error in
                continuation.resume(returning: success)
            }
        }
        
        if success {
            return .result(dialog: "Successfully saved to Health.")
        } else {
            return .result(dialog: "Couldn't save to Health.")
        }
    }
}
