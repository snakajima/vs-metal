{
  "title" : "Delicious",
  "pipeline" : [
    {
      "name" : "lighter",
      "attr" : {
        "ratio" : 1.05
      },
      "ui" : {

      }
    },
    {
      "name" : "enhancer",
      "attr" : {
        "red" : [
          0,
          0.9
        ],
        "green" : [
          0,
          1
        ],
        "blue" : [
          0,
          1
        ]
      },
      "ui" : {

      }
    },
    {
      "name" : "saturate",
      "ui":{ "primary":["ratio"] }, 
      "attr" : {
        "ratio" : 0.15,
        "weight" : [
          0.2126,
          0.7151999999999999,
          0.0722
        ]
      },
      "ui" : {
        "hidden" : [
          "weight"
        ]
      }
    },
    {
      "name" : "fork"
    },
    {
      "name" : "gaussian_blur",
      "attr" : {
        "sigma" : 2
      },
      "ui" : {

      }
    },
    {
      "name" : "differentiate",
      "attr" : {
        "ratio" : 2
      },
      "ui" : {

      }
    },
  ]
}
