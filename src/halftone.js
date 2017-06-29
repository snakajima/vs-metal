{
    "pipeline":[{
        "name":"gaussian_blur",
               "attr":{
                  "sigma": [3.0],
               }
    },{
        "name":"halftone",
                "attr":{
                    "radius": [8.0],
                    "color1": [0.0, 0.0, 0.4, 1.0],
                    "color2": [1.0, 1.0, 0.7, 1.0],
                }
    }]
}
