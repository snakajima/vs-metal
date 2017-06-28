{
    "pipeline":[{
        "name":"gaussianblur",
        "attr":{
            "sigma": [2.0],
        }
    },{
        "name":"fork",
    },{
        "name":"gaussianblur",
        "attr":{
            "sigma": [2.0],
        }
    },{
        "name":"toone",
    },{
        "name":"swap"
    },{
        "name":"sobel",
    },{
        "name":"canny_edge",
    },{
        "name":"overlay"
    }]
}
