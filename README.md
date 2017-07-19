# VideoShader for Metal

This is Metal version of VideoShader, a real-time video processing script engine for iOS (and MacOS later). 

It allows you to describe video processing pipelines using a very simple JSON-based scripting langauge. 

For example, the following script applies the monochrome filter and Gaussian Blur filter in sequence. 

```
{
    "pipeline":[{
        "name":"mono",
    },{
        "name":"gaussianblur",
        "attr":{
            "sigma" : [5.0]
        }
    }]
}
```

In order to apply this filter to a metal texture, you need to compile it into a VSRuntime object first. 

```
    let context = VSContext(device: MTLCreateSystemDefaultDevice()!)
    let script = VSScript(json: json)
    let runtime = script.compile(context: context)
```

You need to store the context object and the runtime object somewhere for later use. 

Then, when you receive a metal texture to be processed from the source (such as a camera), 
call the set(texture:sampleBuffer) method of the VSContext object 
and call the encoded(commandBuffer:context:) method to let the GPU process it.
```
    context.set(texture: textureIn, sampleBuffer: nil)
    let commandBuffer = context.makeCommandBuffer()
    runtime.encode(commandBuffer:commandBuffer, context:context)
    commandBuffer.commit()

    let textureOut = context.pop()?.texture
    // do something with the filtered texture
```

Please remember that the GPU processes it asynchronously. Thererefore, you need to process 
the content of textureOut either in a completion handler or another GPU instruction on the same queue.

