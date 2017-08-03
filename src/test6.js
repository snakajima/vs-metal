{
    "pipeline":[
                { "name":"fork" },
                { "name":"mono" },
                { "name":"derivative" },
                { "name":"gaussian_blur",
                "attr":{
                "sigma": 2.0,
                }
                },
                { "name":"harris_detector", "attr":{"sensitivity":10.0 } },
                { "name":"local_non_max_suppression", "attr":{"threshold":0.1} },
                { "name":"gaussian_blur",
                "attr":{
                "sigma": 4.0,
                }
                },
                { "name":"step" },
                { "name":"alpha" },
                ]
}

