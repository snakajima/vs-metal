{
    "pipeline":[{
        "name":"gaussianblur",
        "attr":{
            "sigma": [2.0],
        }
    },{
        "name":"mono",
    },{
        "name":"sobel",
    },{
        "name":"invert",
    },{
        "name":"boolean",
        "attr":{
            "range": [0.0, 0.9],
            "color1": [1.0, 1.0, 1.0, 1.0],
            "color2": [0.0, 0.0, 0.0, 1.0],
        }
    }]
}
