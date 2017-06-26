# VideoShader for Metal

*UNDER CONSTRUCTION*

This is Metal version of VideoShader, a real-time video processing script engine for iOS (and possible MacOS). 

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
