{
    "pipeline":[{
        "name":"fork",
    },{
        "name":"blur",
    },{
        "name":"blur",
    },{
        "name":"blur",
    },{
        "name":"blur",
    },{
        "name":"fork",
    },{
        "name":"toone",
    },{
        "name":"shift",
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
