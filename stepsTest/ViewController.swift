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
    
    var ecgSamples = [[(Double,Double)]] ()
    var ecgDates = [Date] ()
    var indices = [(Int,Int)]()
    
    let healthStore = HKHealthStore()
    lazy var mainTitleLabel = UILabel()
    lazy var currentECGLineChart = LineChartView()
    lazy var contentView = UIView()
    lazy var analyzeButton = UIButton(type: .system)
    var pickerView = UIPickerView()
    
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
        
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.sizeToFit()
        contentView.addSubview(pickerView)
        pickerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        pickerView.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -100).isActive = true
        pickerView.topAnchor.constraint(equalTo: mainTitleLabel.bottomAnchor, constant: 0).isActive = true
        
        pickerView.heightAnchor.constraint(equalTo: pickerView.heightAnchor).isActive = true
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerView.dataSource = self
        pickerView.delegate = self
        //view.translatesAutoresizingMaskIntoConstraints = false
        
        
        var counter = 0
        
        let healthKitTypes: Set = [HKObjectType.electrocardiogramType()]
        
        healthStore.requestAuthorization(toShare: nil, read: healthKitTypes) { (bool, error) in
            if (bool) {
                
                //authorization succesful
                
                self.getECGsCount { (ecgsCount) in
                    print("Result is \(ecgsCount)")
                    if ecgsCount < 1 {
                        print("You have no ecgs available")
                        return
                    } else {
                        for i in 0...ecgsCount - 1 {
                            self.getECGs(counter: i) { (ecgResults,ecgDate)  in
                                DispatchQueue.main.async {
                                    self.ecgSamples.append(ecgResults)
                                    self.ecgDates.append(ecgDate)
                                    counter += 1
                                    
                                    // the last thread will enter here, meaning all of them are finished
                                    if counter == ecgsCount {
                                        
                                        // sort ecgs by newest to oldest
                                        
                                        var newDates = self.ecgDates
                                        newDates.sort { $0 > $1 }
                                        for element in newDates {
                                            self.indices.append((self.ecgDates.firstIndex(of: element)!,newDates.firstIndex(of: element)!))
                                        }
                                        // indices matrix is a tuple matrix with two categories
                                        // the first is the sorted indice, and the second is the raw
                                        // ecgSamples[indices[0].0] is the newest ecg


                                        self.pickerView.reloadAllComponents()
                                        
                                        
                                        // the line below has use only for the first drop of the pickerView. (At the first time
                                        // picker view doesn't "see" as selected the option
                                        self.updateCharts(ecgSamples: self.ecgSamples[self.indices[0].0], animated: true)
                                    }
                                }
                            }
                        }
                    }
                }
                
                
                
                
            } else {
                print("We had an error here: \n\(String(describing: error))")
            }
        }
    }
    
    func getECGs(counter: Int, completion: @escaping ([(Double,Double)],Date) -> Void) {
        var ecgSamples = [(Double,Double)] ()
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast,end: Date.distantFuture,options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let ecgQuery = HKSampleQuery(sampleType: HKObjectType.electrocardiogramType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]){ (query, samples, error) in
            guard let samples = samples,
                  let mostRecentSample = samples.first as? HKElectrocardiogram else {
                return
            }
            //print(mostRecentSample)
            
            
            let query = HKElectrocardiogramQuery(samples[counter] as! HKElectrocardiogram) { (query, result) in
                
                switch result {
                case .error(let error):
                    print("error: ", error)
                    
                case .measurement(let value):
                    let sample = (value.quantity(for: .appleWatchSimilarToLeadI)!.doubleValue(for: HKUnit.volt()) , value.timeSinceSampleStart)
                    ecgSamples.append(sample)
                    
                case .done:
                    //print("done")
                    DispatchQueue.main.async {
                        completion(ecgSamples,samples[counter].startDate)
                    }
                }
            }
            self.healthStore.execute(query)
        }
        
        
        self.healthStore.execute(ecgQuery)
        //print("everything working here")
        //print(ecgSamples.count)
    }
    
    func getECGsCount(completion: @escaping (Int) -> Void) {
        var result : Int = 0
        let ecgQuery = HKSampleQuery(sampleType: HKObjectType.electrocardiogramType(), predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil){ (query, samples, error) in
            guard let samples = samples
            else {
                return
            }
            result = samples.count
            completion(result)
        }
        self.healthStore.execute(ecgQuery)
    }
    
    func updateCharts(ecgSamples : [(Double,Double)], animated : Bool) {
        if !ecgSamples.isEmpty {
            
            // add line chart with constraints
            
            currentECGLineChart.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(currentECGLineChart)
            currentECGLineChart.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20).isActive = true
            currentECGLineChart.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20).isActive = true
            currentECGLineChart.topAnchor.constraint(equalTo: pickerView.bottomAnchor, constant: 10).isActive = true
            currentECGLineChart.heightAnchor.constraint(equalToConstant: view.frame.size.width + -115).isActive = true
            
            analyzeButton.translatesAutoresizingMaskIntoConstraints = false
            analyzeButton.setTitle("Analyze ECG", for: .normal)
//            analyzeButton.setTitleColor(.label, for: .normal)
//            analyzeButton.showsTouchWhenHighlighted = true
            contentView.addSubview(analyzeButton)
            analyzeButton.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20).isActive = true
            analyzeButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20).isActive = true
//            analyzeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 10).isActive = true
            analyzeButton.topAnchor.constraint(equalTo: currentECGLineChart.bottomAnchor, constant: 10).isActive = true
            analyzeButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
//            analyzeButton.heightAnchor.constraint(equalToConstant: 30.0)
            analyzeButton.addTarget(self, action: #selector(analyzeButtonPressed), for: .touchUpInside)
            
            // customize line chart and add data
            
            
            var entries = [ChartDataEntry] ()
            for i in 0...ecgSamples.count-1 {
                entries.append(ChartDataEntry(x: ecgSamples[i].1, y: ecgSamples[i].0))
            }
            let set1 = LineChartDataSet(entries: entries, label: "ECG data")
            set1.colors = [UIColor.systemRed]
            set1.drawCirclesEnabled = false
            let data = LineChartData(dataSet: set1)
            self.currentECGLineChart.data = data
            currentECGLineChart.setVisibleXRangeMaximum(10)
            
            currentECGLineChart.rightAxis.enabled = false
            //let yAxis = currentECGLineChart.leftAxis
            if animated {
                currentECGLineChart.animate(xAxisDuration: 1.0)
            }
            
            currentECGLineChart.xAxis.labelPosition = .bottom
        }
        
    }
    
    @objc func analyzeButtonPressed() {
        print("Analyze button pressed!")
        print(pickerView.selectedRow(inComponent: 0))
    }

    
}



//MARK: - UIPickerViewDataSource

extension ViewController : UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if ecgDates.count < 1 {
            return 1
        } else {
            return ecgDates.count
        }
    }
    
    
}

extension ViewController : UIPickerViewDelegate {
    
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.updateCharts(ecgSamples: self.ecgSamples[self.indices[row].0], animated: false)
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy HH:mm"
        if ecgDates.count < 1 {
            return "Loading"
        } else {
            return dateFormatter.string(from: ecgDates[indices[row].0])
            
        }
    }
}




