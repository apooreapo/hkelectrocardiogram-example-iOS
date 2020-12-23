//
//  ViewController.swift
//  stepsTest
//
//  Created by User on 20/12/20.
//

import UIKit
import HealthKit



class ViewController: UIViewController {
    
    let healthStore = HKHealthStore()
    
    
    
    
    
    @IBOutlet weak var stepsCountLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Access Step Count
        let healthKitTypes: Set = [HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!]
        
        // Check for Authorization
        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { (bool, error) in
            if (bool) {
                
                
                // Authorization succesful
                self.getSteps { (result) in
                    DispatchQueue.main.async {
                        let stepCount = String(Int(result))
                        self.stepsCountLabel.text = String(stepCount)
                    }
                }
                
            } else {
                print("Error in authorizing user")
            }
        }
        
    }
    
    func getSteps(completion: @escaping (Double) -> Void) {
        let type = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        var interval = DateComponents()
        interval.day = 1
        
        let query = HKStatisticsCollectionQuery(quantityType: type, quantitySamplePredicate: nil, options: [.cumulativeSum], anchorDate: startOfDay, intervalComponents: interval)
        query.initialResultsHandler = { _, result, error in
            var resultCount = 0.0
            result!.enumerateStatistics(from: startOfDay, to: now) { (statistics, _) in
                if let sum = statistics.sumQuantity() {
                    resultCount = sum.doubleValue(for: HKUnit.count())
                }
                DispatchQueue.main.async {
                    completion(resultCount)
                }
            }
            
        }
        query.statisticsUpdateHandler = {
            query, statistics, statisticsCollenction, error in
            
            if let sum = statistics?.sumQuantity() {
                let resultCount = sum.doubleValue(for: HKUnit.count())
                DispatchQueue.main.async {
                    completion(resultCount)
                }
            }
            
        }
        healthStore.execute(query)
    }


}

