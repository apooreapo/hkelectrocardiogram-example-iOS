//
//  ViewController.swift
//  stepsTest
//
//  Created by Orestis Apostolou on 20/12/20.
//

import UIKit
import HealthKit
import Charts



class ViewController: UIViewController {
    
    let healthStore = HKHealthStore()
    lazy var mainTitleLabel = UILabel()
    lazy var currentECGLineChart = LineChartView()
    lazy var contentView = UIView()
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // add title ECG
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)
        contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        contentView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        mainTitleLabel.text = "ECG"
        mainTitleLabel.textAlignment = .center
        mainTitleLabel.font = UIFont.boldSystemFont(ofSize: 35)
        mainTitleLabel.sizeToFit()
        mainTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainTitleLabel)
        mainTitleLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0).isActive = true
        mainTitleLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0).isActive = true
        mainTitleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 40).isActive = true
        mainTitleLabel.heightAnchor.constraint(equalTo: mainTitleLabel.heightAnchor, constant: 0).isActive = true
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        var ecgSamples = [(Double,Double)] ()
        
        let healthKitTypes: Set = [HKObjectType.electrocardiogramType()]
        
        healthStore.requestAuthorization(toShare: nil, read: healthKitTypes) { (bool, error) in
            if (bool) {
                
                //authorization succesful
                
                self.getECGs { (ecgResults) in
                    DispatchQueue.main.async {
                        ecgSamples = ecgResults
                        print(ecgResults.count)
                        print(ecgResults[100].1)
                        self.updateCharts(ecgSamples: ecgResults)
                    }
                    
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
    
    func updateCharts(ecgSamples : [(Double,Double)]) {
        if !ecgSamples.isEmpty {
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            
            // add line chart with constraints
            
            currentECGLineChart.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(currentECGLineChart)
            currentECGLineChart.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20).isActive = true
            currentECGLineChart.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20).isActive = true
            currentECGLineChart.topAnchor.constraint(equalTo: mainTitleLabel.bottomAnchor, constant: 10).isActive = true
            currentECGLineChart.heightAnchor.constraint(equalToConstant: view.frame.size.width + -115).isActive = true
            
            // customize line chart and add data
            
            
            var entries = [ChartDataEntry] ()
            for i in 0...ecgSamples.count-1 {
                entries.append(ChartDataEntry(x: ecgSamples[i].1, y: ecgSamples[i].0))
            }
            let set1 = LineChartDataSet(entries: entries, label: "ECG data")
            set1.drawCirclesEnabled = false
            let data = LineChartData(dataSet: set1)
            self.currentECGLineChart.data = data
            currentECGLineChart.setVisibleXRangeMaximum(10)
            
            currentECGLineChart.rightAxis.enabled = false
            let yAxis = currentECGLineChart.leftAxis
            set1.colors = [UIColor.systemRed]
            currentECGLineChart.animate(xAxisDuration: 1.0)
            
            currentECGLineChart.xAxis.labelPosition = .bottom
        }
        
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





