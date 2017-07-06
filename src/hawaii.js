{
  "title" : "Hawaii",
  "pipeline" : [
    {
      "name" : "fork"
    },
    {
      "name" : "mono",
      "attr" : {
        "color" : [
          1,
          1,
          1,
          1
        ],
        "weight" : [
          0.299,
          0.587,
          0.114
        ]
      },
      "ui" : {

      }
    },
    {
      "name" : "swap"
    },
    {
      "name" : "gaussian_blur",
      "attr" : {
        "sigma" : 6.425
      },
      "ui" : {
        "primary":["sigma"]
      }
    },
    {
      "name" : "alpha",
      "attr" : {
        "ratio" : 1
      },
      "ui" : {
      }
    },
    {
      "name" : "max_blur",
      "attr" : {

      },
      "ui" : {

      }
    },
    {
      "name" : "enhancer",
      "attr" : {
        "red" : [
          0,
          0.5972222
        ],
        "green" : [
          0.2555556,
          0.675
        ],
        "blue" : [
          0.3111111,
          1
        ]
      },
      "ui" : {

      }
    }
  ]
}
