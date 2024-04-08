//
//  BloodPressureShortcuts.swift
//  BloodPressure
//
//  Created by Zsolt Kébel on 08/04/2024.
//

import Foundation
import AppIntents

class BloodPressureShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        
        AppShortcut(intent: AddDataIntent(), phrases: [
            "Record blood pressure measurement \(.applicationName)",
            "Add blood pressure data with \(.applicationName)",
            "Add blood pressure data",
            "Record measurement"
        ],
        shortTitle: "Add Data",
        systemImageName: "pencil.and.list.clipboard")
    }
}
