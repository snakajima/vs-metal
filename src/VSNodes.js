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
    "discard": {
        "type":"control",
        "title":"Discard",
        "description":"Discard the top most layer",
    },
    "shift": {
        "type":"control",
        "title":"Shift",
        "description":"Shift the topmost layer to the bottom",
    },
    "previous": {
        "type":"control",
        "title":"Previous",
        "description":"Texture from previous frame",
    },
    
    "translate": {
        "type":"filter",
        "title":"Translate",
        "description":"Shift the position",
        "attr" : [
            {
                "name":"tx",
                "default":[ 0.0 ],
            },
            {
                "name":"ty",
                "default":[ 0.0 ],
            },
        ],
    },
    "transform": {
        "type":"filter",
        "title":"Transform",
        "description":"Affine transform operation",
        "attr" : [
                  {
                  "name":"abcd",
                  "default":[ 1.0, 0.0, 0.0, 1.0 ],
                  },
                  {
                  "name":"txty",
                  "default":[ 0.0, 0.0 ],
                  },
                  ],
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
    "color": {
        "type":"source",
        "title":"Solid Color",
        "sources":0,
        "description":"Generate a colored layer",
        "attr": [{
            "name":"color",
            "default":[1.0, 1.0, 1.0, 1.0]
        }],
    },
    "colors": {
        "type":"source",
        "title":"Mix of Two Solid Color",
        "sources":0,
        "description":"Generate a colored layer from two colors",
        "attr": [{
                 "name":"color1",
                 "default":[1.0, 1.0, 1.0, 1.0]
                 },{
                 "name":"color2",
                 "default":[0.0, 0.0, 0.0, 1.0]
                 },{
                 "name":"ratio",
                 "default":[0.5]
                 },{
         }],
    },

    "lighter": {
        "type":"filter",
        "title":"Lighter",
        "description":"Make the color lighter",
        "attr": [{
            "name":"ratio",
            "default":[0.5],
            "range":[0.0, 30.0],
        }],
    },
    "hueshift": {
        "type":"filter",
        "title":"Hue Shifter",
        "description":"Shift Hue",
        "attr": [{
            "name":"shift",
            "default":[180.0],
            "range":[0.0, 360.0],
        }],
    },
    "multiply": {
        "type":"blender",
        "sources":2,
        "title":"Multiply",
        "description":"Multiply-blend two layers",
    },
    "screen": {
        "type":"blender",
        "sources":2,
        "title":"Screen",
        "description":"Screen-blend two layers",
    },
    "lighten": {
        "type":"blender",
        "sources":2,
        "title":"Lighten",
        "description":"Lighter-blend two layers",
    },
    "darken": {
        "type":"blender",
        "sources":2,
        "title":"Darken",
        "description":"Darken-blend two layers",
    },

    "overlay": {
        "type":"blender",
        "sources":2,
        "title":"Overlay",
        "description":"Muitply or screen blend two layers",
    },
    "colordodge": {
        "type":"blender",
        "sources":2,
        "title":"Color Dodge",
        "description":"Color dodge blend two layers",
    },
    "colorburn": {
        "type":"blender",
        "sources":2,
        "title":"Color Burn",
        "description":"Color burn blend two layers",
    },
    "hardlight": {
        "type":"blender",
        "sources":2,
        "title":"Hard Light",
        "description":"Hard light blend two layers",
    },
    "softlight": {
        "type":"blender",
        "sources":2,
        "title":"Soft Light",
        "description":"Soft light blend two layers",
    },
    "difference": {
        "type":"blender",
        "sources":2,
        "title":"Difference",
        "description":"Difference blend two layers",
    },
    
    "differentiate": {
        "type":"blender",
        "sources":2,
        "title":"Differentiate",
        "description":"Enlarge the difference between two layers",
        "attr": [{
            "name":"ratio",
            "default": [0.5],
            "range":[0.0, 10.0],
        }],
    },
    "exclusion": {
        "type":"blender",
        "sources":2,
        "title":"Exclusion",
        "description":"Exclusion blend two layers",
    },
    "hue": {
        "type":"blender",
        "sources":2,
        "title":"Hue",
        "description":"Hue blend two layers",
    },
    "saturation": {
        "type":"blender",
        "sources":2,
        "title":"Saturation",
        "description":"Saturation blend two layers",
    },
    "colorblend": {
        "type":"blender",
        "sources":2,
        "title":"Color",
        "description":"Color blend two layers",
    },
    "luminosity": {
        "type":"blender",
        "sources":2,
        "title":"Luminosity",
        "description":"Luminosity blend two layers",
    },

    
    "blur": {
        "type":"filter",
        "title":"Blur",
        "blur":true,
        "description":"lur",
    },
    "alphamask": {
        "type":"blender",
        "sources":2,
        "title":"Alpha Mask",
        "description":"Alpha mask one layer with another",
    },
    "contrast": {
        "type":"filter",
        "title":"Contrast",
        "description":"Change the contrast",
        "attr": [{
            "name":"enhance",
            "default":[0.5],
        }],
    },

    "anti_alias": {
        "type":"filter",
        "title":"Anti Alias",
        "description":"Anti Alias",
        "vertex":"convolve",
    },
    "saturate": {
        "type":"filter",
        "title":"Saturate",
        "description":"Saturate/desaturate the color",
        "attr": [{
            "name":"ratio",
                "default":[0.5],
                "range":[-1.0, 1.0],
                 },{
            "name":"weight",
                "default":[0.2126,0.7152,0.0722],
        }],
    },
    "stretch": {
        "type":"filter",
        "title":"Stretch",
        "description":"Stretch x or y direction",
        "vertex":"stretch",
        "attr": [{
            "name":"ratio",
                "default":[1.0, 1.0],
                "range":[1.0, 2.0],
        }],
    },
    
    "tilt_shift": {
        "type":"filter",
        "title":"Tilt Shift",
        "description":"Miniature faking",
        "blur":true,
        "orientation":true,
        "vertex":"blur",
        "attr" : [{
            "name":"radius",
                "default":16.0,
                "range":[8.0, 24.0],
                  },{
            "name":"factor",
                "default":2.0,
                "range":[0.5, 3.0],
                  },{
            "name":"position",
                "default":0.5,
                "range":[0.0, 1.0],
        }],
    },
    "emboss" : {
        "type":"filter",
        "title":"Emboss",
        "description":"*Apply after Sobel filter",
        "attr": [{
            "name":"rotation",
                "default":0.0,
                "range":[-3.14159265, 3.14159265]
        }]
    },
    "embold": {
        "type":"filter",
        "title":"Embold",
        "blur":true,
        "vertex":"blur",
        "description":"Embold",
        "attr" : [{
            "name":"radius",
                "default":4.0,
                "range":[1.0, 8.0],
        }],
    },
    "invertalpha": {
        "type":"filter",
        "title":"Invert Alpha",
        "description":"Invert the alpha channel",
    },
    
}
