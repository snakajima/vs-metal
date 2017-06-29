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
        "attr":{
            "threshold": [0.19],
            "thin": [0.50],
        }
    },{
        "name":"anti_alias"
    },{
        "name":"alpha"
    }]
}
