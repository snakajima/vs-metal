{
    "pipeline":[{
        "name":"fork",
    },{
        "name":"gaussianblur",
        "attr":{
            "sigma": [2.0],
        }
    },{
        "name":"mono",
    },{
        "name":"sobel2",
    },{
        "name":"canny_edge",
    },{
        "name":"swap"
    },{
        "name":"gaussianblur",
        "attr":{
            "sigma": [2.0],
        }
    },{
        "name":"toone",
    },{
        "name":"alpha"
    }]
}
