//
//  MonteCarloPiData.swift
//  MetalMonteCarlo
//
//  Created by Robert Nasuti on 12/1/15.
//  Copyright © 2015 Robert Nasuti. All rights reserved.
//

import Cocoa

class MonteCarloPiData: NSObject {
    func calculatePi(points:Int)-> (pi: Float, timeToCalculate: Double) {
        var x = [Float]()
        var y = [Float]()
        var counter = 0
        
        //Generate the points for the calculation
        for (var t = 0; t <= points; t++) {
            x.append(Float(arc4random())/Float(UInt32.max))
            y.append(Float(arc4random())/Float(UInt32.max))
        }
        
        //Start Pi Calculation (Serial)
        let start = NSDate()
        for (var i = 0; i <= points; i++) {
            if((x[i] * x[i]) + (y[i] * y[i]) <= 1.0) {
                counter++
            }
        }
        let stop = NSDate()
        //Stop Pi Calculation (Serial)
        
        return (Float(Float(4 * counter)/Float(points)), stop.timeIntervalSinceDate(start))
    }
}
