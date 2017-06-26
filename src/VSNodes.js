{
    "fork": {
        "type":"control",
        "title":"Duplicate",
        "description":"Duplicate the topmost layer",
    },
    "swap": {
        "type":"control",
        "title":"Swap",
        "description":"Swap two topmost layers",
    },
    "mono": {
        "type":"filter",
        "title":"Monochrome",
        "description":"Convert to monochrome color",
        "attr" : [
            {
                "name":"weight",
                "default":[ 0.299, 0.587, 0.114 ],
            },
            {
                "name":"color",
                "default":[ 1.0, 1.0, 1.0, 1.0 ],
            },
        ],
    },
    "gaussianblur": {
        "type":"filter",
        "title":"Gaussian Blur",
        "description":"Gaussian Blur",
        "attr" : [
            {
                "name":"sigma",
                "default":[4.0],
            },
        ],
    },
    "sobel": {
        "type":"filter",
        "title":"Sobel",
        "description":"Sobel operator (for Canny Edge Detector)",
        "attr": [{
                "name":"weight",
                "default":[ 0.299, 0.587, 0.114 ],
        }]
    },
    "pyramid": {
        "type":"filter",
        "title":"Pyramid",
        "description":"Pyramid Images",
        "attr": [{
            "name":"weight",
            "default":[ 0.299, 0.587, 0.114 ],
        }]
    },
    "laplacian": {
        "type":"filter",
        "title":"Laplacian",
        "description":"Laplacian Images",
    },
    "alpha": {
        "type":"blender",
        "title":"Alpha",
        "description":"Alpha blend two layers",
        "sources":2,
        "attr": [{
                "name":"ratio",
                "default":[1.0],
        }],
    },
}
