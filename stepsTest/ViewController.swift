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
        
        var ecgSamples = [(Double,Double)] ()
        
        let healthKitTypes: Set = [HKObjectType.electrocardiogramType()]
        
        healthStore.requestAuthorization(toShare: nil, read: healthKitTypes) { (bool, error) in
            if (bool) {
                //authorization succesful
                self.getECGs { (ecgResults) in
                    print(ecgResults.count)
                    print(ecgResults[100].0)
                }
                
                
            } else {
                print("We had an error here: \n\(String(describing: error))")
            }
        }
    }
    
    func getECGs(completion: @escaping ([(Double,Double)]) -> Void) {
        var ecgSamples = [(Double,Double)] ()
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast,end: Date.distantFuture,options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let ecgQuery = HKSampleQuery(sampleType: HKObjectType.electrocardiogramType(), predicate: predicate, limit: 0, sortDescriptors: [sortDescriptor]){ (query, samples, error) in
            guard let samples = samples,
                  let mostRecentSample = samples.first as? HKElectrocardiogram else {
                return
            }
            print(mostRecentSample)
            
            let query = HKElectrocardiogramQuery(mostRecentSample) { (query, result) in
                
                switch result {
                case .error(let error):
                    print("error: ", error)
                    
                case .measurement(let value):
                    let sample = (value.quantity(for: .appleWatchSimilarToLeadI)!.doubleValue(for: HKUnit.volt()) , value.timeSinceSampleStart)
                    ecgSamples.append(sample)
                    
                case .done:
                    print("done")
                    DispatchQueue.main.async {
                        completion(ecgSamples)
                    }
                }
            }
            self.healthStore.execute(query)
        }
        
        
        self.healthStore.execute(ecgQuery)
        print("everything working here")
        print(ecgSamples.count)
    }
    
}




//        // Access Step Count
//        let healthKitTypes: Set = [HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!]
//
//        // Check for Authorization
//        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { (bool, error) in
//            if (bool) {
//
//
//                // Authorization succesful
//                self.getSteps { (result) in
//                    DispatchQueue.main.async {
//                        let stepCount = String(Int(result))
//                        self.stepsCountLabel.text = String(stepCount)
//                    }
//                }
//
//            } else {
//                print("Error in authorizing user")
//            }
//        }
//
//    }
//
//    func getSteps(completion: @escaping (Double) -> Void) {
//        let type = HKQuantityType.quantityType(forIdentifier: .stepCount)!
//        let now = Date()
//        let startOfDay = Calendar.current.startOfDay(for: now)
//        var interval = DateComponents()
//        interval.day = 1
//
//        let query = HKStatisticsCollectionQuery(quantityType: type, quantitySamplePredicate: nil, options: [.cumulativeSum], anchorDate: startOfDay, intervalComponents: interval)
//        query.initialResultsHandler = { _, result, error in
//            var resultCount = 0.0
//            result!.enumerateStatistics(from: startOfDay, to: now) { (statistics, _) in
//                if let sum = statistics.sumQuantity() {
//                    resultCount = sum.doubleValue(for: HKUnit.count())
//                }
//                DispatchQueue.main.async {
//                    completion(resultCount)
//                }
//            }
//
//        }
//        query.statisticsUpdateHandler = {
//            query, statistics, statisticsCollenction, error in
//
//            if let sum = statistics?.sumQuantity() {
//                let resultCount = sum.doubleValue(for: HKUnit.count())
//                DispatchQueue.main.async {
//                    completion(resultCount)
//                }
//            }
//
//        }
//        healthStore.execute(query)
//    }





