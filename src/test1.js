{
    "variables":{
        "myshift":{
            "type":"sin",
            "range":[0.0, 180.0],
            "interval":2.0
        }
    },
    "pipeline":[{
        "name":"hueshift",
        "attr":{
            "shift":"myshift"
        }
    }]
}
