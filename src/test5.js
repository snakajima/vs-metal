{
    "pipeline":[{
        "name":"blur",
    },{
        "name":"blur",
    },{
        "name":"fork",
    },{
        "name":"blur",
    },{
        "name":"blur",
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
