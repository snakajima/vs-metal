{
    "variables":{
        "myratio":{
            "type":"sin",
            "range":[0.0, 1.0],
            "interval":2.0
        }
    },
    "pipeline":[{
        "name":"lighter",
        "attr":{
            "ratio": "myratio",
        }
    }]
}
