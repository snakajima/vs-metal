{
    "title":"Gradient",
    "pipeline":[
        { "name":"gradient",
            "attr":{"color1":[0.0, 0.0, 1.0, 1.0], "color2":[1.0, 0.0, 0.0, 1.0]} },
        { "name":"swap" },
        { "name":"gaussian_blur", "attr":{"sigma":2.0} },
        { "name":"fork" },
        { "name":"sobel" },
        { "name":"canny_edge", "attr":{ "threshold":0.39, "thin":0.50 } },
        { "name":"anti_alias" },
        { "name":"swap" },
        { "name":"toone", "ui":{ "hidden":["weight"] } },
        { "name":"color" },
        { "name":"alpha", "attr":{"ratio":0.5} },
        { "name":"mono", "ui":{ "hidden":["weight"] } },
        { "name":"swap" },
        { "name":"alpha", "attr":{"ratio":0.10} },
        { "name":"luminosity" }
    ]
}
