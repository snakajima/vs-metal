{
  "title" : "Freeza",
  "pipeline" : [
    {
      "name" : "gaussian_blur",
      "attr" : {
        "sigma" : 4
      },
      "ui" : {

      }
    },
    {
      "name" : "fork"
    },
    {
      "name" : "gaussian_blur",
      "attr" : {
        "sigma" : 8
      },
      "ui" : {

      }
    },
    {
      "name" : "boolean",
      "attr" : {
        "range" : [
          0.2944444,
          0.6972222
        ],
        "color1" : [
          0.95,
          1,
          1,
          1
        ],
        "weight" : [
          0.299,
          0.587,
          0.114
        ],
        "color2" : [
          0,
          0,
          0,
          1
        ]
      },
      "ui" : {
        "hidden" : [
          "weight"
        ]
      }
    },
    {
      "name" : "swap"
    },
    {
      "name" : "sobel",
      "attr" : {
        "weight" : 2.088889
      },
      "ui" : {

      }
    },
    {
      "name" : "canny_edge",
      "attr" : {
        "color" : [
          0.3333333,
          0,
          0.5861111,
          1
        ],
        "thin" : 0,
        "threshold" : 0.21
      },
      "ui" : {

      }
    },
    {
      "name" : "anti_alias",
      "attr" : {

      },
      "ui" : {

      }
    },
    {
      "name" : "alpha",
      "attr" : {
        "ratio" : 1
      },
      "ui" : {

      }
    }
  ]
}
