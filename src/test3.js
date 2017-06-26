{
    "pipeline":[{
        "name":"gaussianblur",
        "attr":{
            "sigma": [2.0]
        }
    },{
        "name":"fork",
    },{
        "name":"gaussianblur",
        "attr":{
            "sigma": [4.0]
        }
    },{
        "name":"invert",
    },{
        "name":"alpha",
        "attr":{
            "ratio": [0.5]
        }
    },{
        "name":"boolean",
        "attr":{
            "range": [0.0, 0.5],
            "color1": [1.0, 1.0, 1.0, 1.0],
            "color2": [0.0, 0.0, 0.0, 1.0]
        }
    }]
}
