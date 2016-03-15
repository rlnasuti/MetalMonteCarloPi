//
//  mcpiShader.metal
//  MetalMonteCarlo
//
//  Created by Robert Nasuti on 11/24/15.
//  Copyright © 2015 Robert Nasuti. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

//This function has the input buffer at index 0, the output buffer at index 1, and is passed in a "thread id" from the system
//Each threadgroup works on a different data point in parallel
kernel void mcpiShader(
                                   const device float2 *inPoints [[ buffer(0) ]],
                                   device bool *inCircle [[ buffer(1) ]],
                                   uint id [[thread_position_in_grid]]
                       )
{
    float x = inPoints[id][0];
    float y = inPoints[id][1];
    
    if ((x * x) + (y * y) <= 1.0)
        inCircle[id] = true;
    else
        inCircle[id] = false;
    }