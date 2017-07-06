{
    "title":"Smooth Skin",
    "pipeline":[
        { "name":"stretch", "attr": { "ratio":[1.0, 1.02] } },
        { "name":"lighter", "attr":{ "ratio":1.025 } },
        { "name":"enhancer", "attr":{ "red":[0.0, 0.95], "blue":[0.05, 1.0] } },
        { "name":"fork" },
        { "name":"gaussian_blur", "attr":{ "sigma":2.0 } },
        { "name":"fork" },
        { "name":"shift" },
        { "name":"sobel" },
        { "name":"canny_edge", "attr":{ "threshold":0.21, "thin":0.0 } },
        { "name":"anti_alias", "repeat":2 },
        { "name":"mixer" }
    ]
}
