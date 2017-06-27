{
    "pipeline":[{
        "name":"fork",
    },{
        "name":"gaussianblur",
        "attr":{
            "sigma": [2.0]
        }
    },{
        "name":"toone",
    },{
        "name":"swap",
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
    },{
        "name":"alpha",
    }]
}
