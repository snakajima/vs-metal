{
    "title":"Yes We Can",
    "pipeline":[
        { "name":"blur" },
        { "name":"blur" },
        { "name":"fork" },
        { "name":"fork" },
        { "name":"boolean", "ui":{ "hidden":["weight"] },
            "attr":{
                "range":[0.0, 0.25],
                "color1":[0.83, 0.10, 0.13, 1.0],
                "color2":[0.04, 0.19, 0.30, 1.0] } },
        { "name":"swap" },
        { "name":"boolean", "ui":{ "hidden":["weight"] },
            "attr":{
                "range":[0.5, 0.75],
                "color2":[0.44, 0.59, 0.62, 1.0] } },
        { "name":"alpha" },
        { "name":"swap" },
        { "name":"boolean", "ui":{ "hidden":["weight"] },
            "attr":{
                "range":[0.75, 1.0],
                "color2":[0.99, 0.89, 0.65, 1.0] } },
        { "name":"alpha" },
    ]
}
