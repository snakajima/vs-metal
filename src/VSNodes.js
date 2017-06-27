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
    "sobel_mps": {
        "type":"filter",
        "title":"Sobel",
        "description":"Sobel operator (for Canny Edge Detector)",
        "attr": [{
            "name":"weight",
            "default":[ 0.299, 0.587, 0.114 ],
        }]
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
    "canny_edge": {
        "type":"filter",
        "title":"Canny Edge Detector",
        "description":"*Apply after Sobel filter to detect edge",
        "attr": [{
            "name":"threshold",
            "default":[0.15],
        },{
            "name":"thin",
            "default":[0.5],
        },{
            "name":"color",
            "default":[0.0, 0.0, 0.0, 1.0]
        }],
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

    "tint": {
        "type":"filter",
        "title":"Tint",
        "description":"Tint with a color",
        "attr" : [{
                "name":"ratio",
                "default":[0.5],
                  },{
                "name":"color",
                "default":[0.0, 0.0, 0.0, 1.0],
        }],
    },
    "enhancer": {
        "type":"filter",
        "title":"Enhancer",
        "description":"Enhance each color component",
        "attr" : [{
                "name":"red",
                "default":[0.0, 1.0],
                  },{
                "name":"green",
                "default":[0.0, 1.0],
                  },{
                "name":"blue",
                "default":[0.0, 1.0],
        }],
    },
    "hue_filter": {
        "type":"filter",
        "title":"Hue Detector",
        "description":"detect",
        "attr": [{
                "name":"hue",
                "default":[0.0, 180.0],
                "range":[0.0, 360.0],
                 },{
                "name":"chroma",
                "default":[0.2, 1.0],
        }],
    },
    "mixer": {
        "type":"mixer",
        "title":"Mixer",
        "description":"Mix two layers using third layer's alpha",
        "sources":3,
    },
}
