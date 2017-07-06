{
    "title":"Hipass",
    "pipeline":[
        { "name":"fork" },
        { "name":"gaussian_blur", "attr":{"sigma":4.0} },
        { "name":"invert" },
        { "name":"alpha", "attr":{"ratio":0.5} },
        { "name":"contrast", "attr":{"enhance":1.0} }
    ]
}
