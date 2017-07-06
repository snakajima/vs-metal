{
    "title":"Tennis Ball Tracker",
    "pipeline":[
        { "name":"previous" },
        { "name":"color_tracker",
          "attr":{ "color":[1.0, 1.0, 0.12], "ratio":0.95, "range":[0.34, 0.80] },
          "ui":{ "primary":["ratio", "color", "range"] }
        },
        { "name":"fork" }
    ]
}
