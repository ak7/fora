recordModule = require('./record')
utils = require('../lib/utils')
Q = require('../lib/q')
models = require('./')

class Article extends recordModule.Record

    @describeType: {
            type: @,
            inherits: recordModule.Record,
            name: 'article',
            description: 'Article',
            fields: {
                title: { type: 'string', required: false, maxLength: 200 }
                subtitle: { type: 'string', required: false, maxLength: 200 },
                synopsis: { type: 'string', required: false, maxLength: 2000 },
                cover: { type: 'string', required: false, maxLength: 200 },
                coverAlt: { type: 'string', required: false, maxLength: 200 },
                smallCover: { type: 'string', required: false, maxLength: 200, validate: -> if @cover and not @smallCover then 'Missing small cover.' else true },
                content: { type: 'string', required: false, maxLength: 100000 },
                format: { type: 'string', $in: ['markdown'], map: { default: 'markdown' } },
            },
            stub: 'title',
            formattedFields: [
                { field: 'content', format: 'format' }
            ]
        }



    constructor: (params) ->
        super
        @type ?= 'article'



    render: (name = "standard") =>
        switch name
            when 'standard'
                new controls.RecordView {
                    itemPane: [
                        new controls.Cover,
                        new controls.Title,
                        new controls.Authorship { type: 'small'},
                        new controls.Content
                    ],
                    sidebar: [
                        new controls.Authorship
                    ]
                }



    getView: (name = "standard") =>
        switch name
            when "snapshot"
                {
                    image: @smallCover,
                    @title,
                    @createdBy,
                    id: @_id.toString(),
                    @stub
                } 
            when "card"
                {
                    image: @smallCover,
                    @title,
                    content: @formatData(@content, @format),
                    @createdBy,
                    @collection,
                    id: @_id.toString(),
                    @stub
                }



exports.Article = Article

