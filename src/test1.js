{
    "pipeline":[{
        "name":"color",
        "attr":{
            "color": [1.0, 0.0, 0.0, 1.0],
        }
    },{
        "name":"swap",
    },{
        "name":"hue_filter",
                "attr":{
                "hue": [325.0, 12.5],
                "chroma": [0.15, 1.0],
                }
    },{
        "name":"alphamask",
    },{
        "name":"color",
        "attr":{
            "color": [1.0, 1.0, 0.0, 1.0],
        }
    },{
        "name":"swap",
    },{
        "name":"alpha",
    }]
}
