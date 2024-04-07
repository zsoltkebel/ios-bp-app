//
//  HealthKitManager.swift
//  blood_pressure
//
//  Created by Zsolt Kébel on 08/02/2024.
//

import Foundation
import HealthKit

enum HKShareError: Error {
    case sharingNotAuthorisedForAllSamples
}

class HealthKitManager {
    fileprivate let healthKitStore = HKHealthStore()
    
    func isSharingAuthorizedForAllSamples() -> Bool {
        return healthKitStore.authorizationStatus(for: HKCorrelationType(.bloodPressure)) == .sharingAuthorized &&
        healthKitStore.authorizationStatus(for: HKQuantityType(.heartRate)) == .sharingAuthorized
    }
    
    func authorizationRequestHealthKit(completion: @escaping (Bool, Error?) -> Void) {
        // 1
        guard HKHealthStore.isHealthDataAvailable() else {
            let error = NSError(domain: "com.zsoltkebel.mobile", code: 999,
                                userInfo: [NSLocalizedDescriptionKey : "Healthkit not available on this device"])
            completion(false, error)
            print("HealthKit not available on this device")
            return
        }
        // 2
        let types: Set<HKSampleType> = [
            HKQuantityType(.bloodPressureSystolic),
            HKQuantityType(.bloodPressureDiastolic),
            HKQuantityType(.heartRate)
        ]
        
        // 3
        healthKitStore.requestAuthorization(toShare: types, read: types) { (success: Bool, error: Error?) in
            completion(success, error)
        }
    }

    func save(systolic: Int, diastolic: Int, heartRate: Int, date: Date = .now, completion: ((_ success: Bool, _ error: Error?) -> Void)? = nil) {
        
        // Check authorization status
        
        guard isSharingAuthorizedForAllSamples() else {
            completion?(false, HKShareError.sharingNotAuthorisedForAllSamples)
            return
        }
        
        // Blood Pressure
        
        let bloodPressureCorrelation = HKCorrelation.bloodPressure(
            systolic: Double(systolic),
            diastolic: Double(diastolic),
            date: date
        )
        
        // Heart Rate
        
        let heartRateSample = HKQuantitySample.heartRate(
            bpm: Double(heartRate),
            date: date
        )
        
        // Save to Health
        
        healthKitStore.save([bloodPressureCorrelation, heartRateSample]) { (success: Bool, error: Error?) in
            completion?(success, error)
        }
    }
    
    func readSampleByBloodPressure(completion: @escaping ([Reading]) -> Void) {
        let startDate = Calendar.current.date(byAdding: .day, value: -14, to: Date())
        let now   = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let type = HKCorrelationType(.bloodPressure)
        let sampleQuery = HKSampleQuery(sampleType: type, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: nil)
        { (sampleQuery, results, error ) -> Void in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            //            print(results)
            
            guard let samples = results as? [HKCorrelation] else {
                return
            }
            
            var readings: [Reading] = []
            for sample in samples {
                if let sys = sample.objects(for: HKQuantityType(.bloodPressureSystolic)).first as? HKQuantitySample,
                   let dia = sample.objects(for: HKQuantityType(.bloodPressureDiastolic)).first as? HKQuantitySample {
                    
                    let value1 = sys.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
                    let value2 = dia.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
                    
                    print("\(value1) / \(value2)")
                    readings.append(Reading(sys: value1, dia: value2, heartRate: 0, date: sample.startDate))
                }
            }
            
            completion(readings)
            //            print(samples)
        }
        self.healthKitStore.execute(sampleQuery)
        
    }
    
    func fetchHeartRateData(completion: (([HKQuantitySample]) -> Void)? = nil) {
        let startDate = Calendar.current.date(byAdding: .day, value: -14, to: Date())
        let now   = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let type = HKQuantityType(.heartRate)
        let sampleQuery = HKSampleQuery(sampleType: type, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: nil)
        { (sampleQuery, results, error ) -> Void in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let samples = results as? [HKQuantitySample] else {
                return
            }
            completion?(samples)
            print(samples)
        }
        self.healthKitStore.execute(sampleQuery)
    }
}

extension HKCorrelation {
    
    /// Initialiser for blood pressure correlation where start and end times are the same
    class func bloodPressure(systolic: Double, diastolic: Double, date: Date) -> HKCorrelation{
        
        let systolicSample = HKQuantitySample(
            type: HKQuantityType(.bloodPressureSystolic),
            quantity: HKQuantity(unit: .millimeterOfMercury(), doubleValue: Double(systolic)),
            start: date,
            end: date
        )
        
        let diastolicSample = HKQuantitySample(
            type: HKQuantityType(.bloodPressureDiastolic),
            quantity: HKQuantity(unit: .millimeterOfMercury(), doubleValue: Double(diastolic)),
            start: date,
            end: date
        )
        
        return HKCorrelation(
            type: HKCorrelationType(.bloodPressure),
            start: date,
            end: date,
            objects: [systolicSample, diastolicSample]
        )
    }
}

extension HKQuantitySample {
    
    /// Heart Rate with matching start and end date
    class func heartRate(bpm: Double, date: Date) -> HKQuantitySample {
        
        return HKQuantitySample(
            type: HKQuantityType(.heartRate),
            quantity: HKQuantity(unit: .count().unitDivided(by: .minute()), doubleValue: Double(bpm)),
            start: date,
            end: date
        )
    }
}
