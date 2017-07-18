{
    "title":"Sports Light",
    "pipeline":[
        { "name":"fork" },
        { "name":"repeat",
          "count":8,
          "nodes":[
                 { "name":"previous" },
                 { "name":"fork" },
                 { "name":"shift" },
                 ],
        },

        { "name":"repeat",
          "count":8,
          "nodes":[
                 { "name":"lighten" },
                 ],
        }
    ]
}
