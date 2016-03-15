//
//  MasterViewController.swift
//  MetalMonteCarlo
//
//  Created by Robert Nasuti on 12/1/15.
//  Copyright © 2015 Robert Nasuti. All rights reserved.
//

import Cocoa
import MetalKit

class MasterViewController: NSViewController {
    
    let mcpi:MonteCarloPiData = MonteCarloPiData()              //class for serial calculation of pi
    let points = 30000000                                       //number of points to use in the calculation
    
    var device: MTLDevice! = nil                                //The GPU
    var defaultLibrary: MTLLibrary! = nil                       //The Shader library
    var commandQueue: MTLCommandQueue! = nil                    //Queue for holding GPU pipeline commands
    var pipelineState: MTLComputePipelineState! = nil           //Configurable pipeline state
    var commandBuffer: MTLCommandBuffer! =  nil                 //GPU commands, related to commandQueue
    var outVectorBuffer: MTLBuffer! = nil                       //GPU buffer for holding results of shader calculation
    var commandEncoder: MTLComputeCommandEncoder! = nil         //Structure for encoding commands to the GPU pipeline
    var myvectorByteLength: Int! = nil                          //Buffer length
    var outVectorByteLength: Int! = nil                         //Buffer length
    var myvector: [float2]! = nil                               //Holds input data
    var resultData: [Bool]! = nil                               //Holds result data
    var finalResultArray: [Bool]! = nil                         //Holds result data - can probably be factored out
    var data: NSData! = nil                                     //Holds result data in raw form
    var counter: Int = 0                                        //Number of points generated that fall within the unit circle
    
    //UI Labels
    @IBOutlet weak var ParallelPi: NSTextField!
    @IBOutlet weak var SerialPi: NSTextField!
    @IBOutlet weak var RatioLabel: NSTextField!
    @IBOutlet weak var SerialTimeToCalculate: NSTextField!
    @IBOutlet weak var ParallelTimeToCalculate: NSTextField!

    //UI Button Press events
    
    //Calculate the ratio of serial to parallel computation time
    @IBAction func CalculateRatio(sender: AnyObject) {
        let parallelTime = ParallelTimeToCalculate.floatValue
        let serialTime = SerialTimeToCalculate.floatValue
        let ratio = serialTime/parallelTime
        
        RatioLabel.stringValue = "The data-parallel calculation is \(ratio) times faster than the serial calculation!"
    }
    
    //Calculate pi serially and display the value
    @IBAction func CalculatePiSerial(sender: AnyObject) {
        let piInstance = mcpi.calculatePi(points)  /*--------------------->                                 //Calculates pi - see MonteCarloPiData.swift for details*/
        SerialPi.stringValue = "Pi = \(piInstance.pi.description)"
        SerialTimeToCalculate.stringValue = "\(piInstance.timeToCalculate.description) seconds"
    }
    
    //Calculate pi in parallel and display the value
    @IBAction func CalculatePi(sender: AnyObject) {
        myvectorByteLength = myvector.count * sizeofValue(myvector[0])                                      //Size of input buffer
        let newVector: [float2] = myvector                                                             //local version of "myvector - solves memory reference problems
        let inVectorBuffer = device.newBufferWithBytes(newVector, length: myvectorByteLength, options: [])  //Create the new buffer for input data
        commandEncoder.setBuffer(inVectorBuffer, offset: 0, atIndex: 0)                                     //Set the input buffer at index 0
        resultData = Array<Bool>(count: myvector.count, repeatedValue: false)                               //Create an array to store the output data
        outVectorByteLength = resultData.count * sizeofValue(resultData[0])                                 //Size of output buffer
        outVectorBuffer = device.newBufferWithBytes(resultData, length: outVectorByteLength, options: [])   //Create output buffer
        commandEncoder.setBuffer(outVectorBuffer, offset: 0, atIndex: 1)                                    //Set the output buffer at index 1
        
        //To-Do: Read up on thread MTLSize optimization
        //This defines the number of threads and thread groups that will
        //work on the data-set in parallel
        let threadsPerGroup = MTLSize(width:16,height:1,depth:1)
        let numThreadgroups = MTLSize(width:(myvector.count+15)/16, height:1, depth:1)
        
        //Start Calculating Pi (Parallel)
        let start = NSDate()
        commandEncoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerGroup)
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        let stop = NSDate()
        let timeInterval = stop.timeIntervalSinceDate(start)
        //Stop Calculating Pi (Parallel)
        
        //Pull the data from the in GPU buffer and store it in Main memory
        data = NSData(bytesNoCopy: outVectorBuffer.contents(), length: resultData.count*sizeof(Bool), freeWhenDone: false)
        var finalResultArrayCopy = Array<Bool>(count: resultData.count, repeatedValue: false)
        data.getBytes(&finalResultArrayCopy, length:resultData.count * sizeof(Bool))
        
        //See how many generated points fell within a unit circle, store that value in counter
        for result in finalResultArrayCopy {
            if (result == true) {
                counter++;
            }
        }
        
        ParallelTimeToCalculate.stringValue = "\(timeInterval) seconds"
        
        //Set pi - ratio of points generated within a unit circle to points generated total (Monte Carlo method)
        let pi: Float = Float(4 * counter)/Float(points)
        ParallelPi.stringValue = "Pi = \(pi)"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupMetal()
        self.myvector = Array<float2>()
        self.populateBuffer()
        
        let kernelFunction = defaultLibrary.newFunctionWithName("mcpiShader")       //binds a Shader function to the kernelFunction variable
        //Create a pipeline setup with kernelFunction, or throw an error
        do {
            try pipelineState = device.newComputePipelineStateWithFunction(kernelFunction!)
        } catch let pipelineError {
            print("Failed to create pipeline state, error \(pipelineError)")
        }
        
        commandEncoder.setComputePipelineState(pipelineState)
    }
    
    func setupMetal() {
        //Access the default GPU of the device this program is being run on
        //1. Get the Device
        device = MTLCreateSystemDefaultDevice()
        
        //Create a queue for commands to the GPU
        //2. Create a command queue
        commandQueue = device.newCommandQueue()
        
        /*Create a new library containing the functions of the default library.
        All .metal files in an Xcode project that builds an application are compiled
        and built into a single default library. In this case, the default Library consists
        of the functions defined in "Shaders.metal" - basic_vertex and basic_fragment*/
        //This library and the vertexData field are step
        //3. Create the resources
        defaultLibrary = device.newDefaultLibrary()
        
        commandBuffer = commandQueue.commandBuffer()
        commandEncoder = commandBuffer.computeCommandEncoder()
    }

    //This function populates an array with <points> number of (x,y) coordinates x=[0,1], y=[0,1] to
    //be used in the monte carlo calculation
    func populateBuffer() {
        var z: float2
        
        for (var i = 0; i <= points; i++) {
            z = float2(x: Float(arc4random())/Float(UInt32.max), y: Float(arc4random())/Float(UInt32.max))
            
            myvector.append(z)
        }
    }
}
