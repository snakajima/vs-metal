{
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
        "attr": [
            {
                "name":"weight",
                "default":[ 0.299, 0.587, 0.114 ],
            },
        ],
    },
}
