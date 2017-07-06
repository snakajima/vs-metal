{
    "title":"Emboss",
    "pipeline":[
        { "name":"gaussian_blur", "attr":{"sigma":3.0} },
        { "name":"sobel" },
        { "name":"emboss", "attr":{"rotation":2.25}, "ui":{ "primary":["rotation"] } },
        { "name":"color", "attr":{"color":[0.55, 0.55, 0.55, 1.0]} },
        { "name":"swap" },
        { "name":"alpha" },
    ]
}
