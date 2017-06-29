{
    "variables":{
        "myratio":{
            "type":"sin",
            "range":[0.0, 1.0],
            "interval":1.0
        }
    },
    "pipeline":[{
        "name":"fork",
    },{
        "name":"gaussian_blur",
        "attr":{
            "sigma": 10.0,
        }
    },{
        "name":"alpha",
        "attr":{
            "ratio": "myratio",
        }
    }]
}
