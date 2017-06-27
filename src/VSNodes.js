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
            "default":[2.0],
            "range":[0.0, 4.0],
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
    "toone": {
        "type":"filter",
        "title":"Toone",
        "attr" : [{
                "name":"levels",
                "default":[4.0],
                "range":[ 2.0, 8.0 ],
        },{
                "name":"weight",
                "default":[ 0.299, 0.587, 0.114 ],
        }],
        "description":"Convert colors to multiple levels",
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
    "invert": {
        "type":"filter",
        "title":"Invert",
        "description":"Invert the color",
    },
    "boolean": {
        "type":"filter",
        "title":"Boolean",
        "description":"Alternate color based on weighted monochrome",
        "attr": [{
            "name":"range",
                "default":[0.0, 0.5],
        },{
            "name":"weight",
                "default":[ 0.299, 0.587, 0.114 ],
        },{
            "name":"color1",
                "default":[0.0, 0.0, 0.0, 0.0],
        },{
            "name":"color2",
                "default":[0.0, 0.0, 0.0, 1.0],
        }],
    },
    "gradientmap": {
        "type":"filter",
        "title":"Gradient Map",
        "description":"Mix two colors using brightness",
        "attr" : [{
            "name":"weight",
            "default":[ 0.299, 0.587, 0.114 ],
        },{
            "name":"color1",
            "default":[ 0.0, 0.0, 0.0, 0.0 ],
        },{
            "name":"color2",
            "default":[ 1.0, 1.0, 1.0, 1.0 ],
        }],
    },
    "halftone": {
        "type":"filter",
        "title":"Half Tone",
        "description":"Convert to halftone color",
        "attr" : [{
                "name":"weight",
                "default":[ 0.299, 0.587, 0.114 ],
              },{
                "name":"color1",
                "default":[ 0.0, 0.0, 0.0, 1.0 ],
              },{
                "name":"color2",
                "default":[ 1.0, 1.0, 1.0, 0.0 ],
              },{
                "name":"radius",
                "default": [5.0],
                "range":[2.0, 100.0],
              },{
                "name":"scale",
                "default": [1.3],
                "range":[0.1, 2.0],
        }],
    },
}
