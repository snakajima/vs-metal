{
    "pipeline":[{
        "filter":"mono",
        "attr":{
            "weight": [0.2126, 0.7152, 0.0722],
            "color": [1.0, 0.0, 0.0, 1.0]
        }
    },{
        "filter":"gaussianblur",
        "attr":{
            "sigma" : [20.0]
        }
    }]
}
