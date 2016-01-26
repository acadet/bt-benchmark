//
//  ViewController.swift
//  BT Benchmark
//
//  Created by Adrien on 25/01/16.
//  Copyright © 2016 Coshx Labs. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var switcher: UISegmentedControl!
    @IBOutlet weak var averageLabel: UILabel!
    @IBOutlet weak var testNumberLabel: UILabel!
    
    private var testNumber = 1
    private var currentIndex = 0
    private lazy var recordedValues = [Double]()
    private var testTimer: NSTimer?
    
    private var engine: BTAdvertiser?
    
    func startTesting() {
        if self.currentIndex == self.testNumber {
            self.testTimer?.invalidate()
            return
        }
        
        self.engine = BTAdvertiser(whenDone: {
                self.label.text = "Result: \($0.microseconds) us"
                
                self.recordedValues.append($0.microseconds)
                var average = self.recordedValues[0]
                for i in 1..<self.recordedValues.count {
                    average += self.recordedValues[i]
                }
                
                average /= Double(self.recordedValues.count)
                
                self.averageLabel.text = "Average: #\(self.recordedValues.count) - \(average) us"
                
                self.currentIndex++
                self.testTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "startTesting", userInfo: nil, repeats: false)
            }, withPolling: self.switcher.selectedSegmentIndex == 0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onReset(sender: AnyObject) {
        self.recordedValues = []
        self.currentIndex = self.testNumber
        self.testTimer?.invalidate()
    }
    
    @IBAction func onStart(sender: AnyObject) {
        self.currentIndex = 0
        self.recordedValues = []
        self.startTesting()
    }
    
    @IBAction func onTestNumberUpdate(sender: AnyObject) {
        let slider = sender as! UISlider
        
        self.testNumber = Int(slider.value)
        self.testNumberLabel.text = "#\(self.testNumber)"
    }
}

