{
    "pipeline":[{
        "name":"fork",
    },{
        "name":"gaussian_blur",
        "attr":{
            "sigma": [4.0]
        }
    },{
        "name":"toone",
    },{
        "name":"swap",
    },{
        "name":"fork",
    },{
        "name":"gaussian_blur",
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
            "range": [0.0, 0.49]
        }
    },{
        "name":"alpha",
    }]
}
