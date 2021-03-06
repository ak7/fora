handlebars = require('handlebars')
Widget = require '../widget'

class Authorship extends Widget
    
    # For large screens
    @template = handlebars.compile '
        <div class="header iconic-section">
            <img src="{{assetUrl}}/{{author.username}}.jpg" alt="{{author.name}}" />
            <h2>{{author.name}}</h2>
            <p>
                {{author.about}}
            </p>
            <p>
                <span class="light-text">Yesterday in <a href="/{{collection.stub}}">{{collection.name}}</a></span>                
            </p>                    
        </div>'
    
    # For tiny and small screens
    @smallTemplate = handlebars.compile '
        <div class="small-page-element tiny-page-element">
            <div class="iconic-desc sub-heading">            
                <img src="{{assetUrl}}/{{author.username}}_t.jpg" alt="{{author.name}}" />
                <span class="text">
                    <a href="/~{{author.username}}">{{author.name}}</a><br />
                    <span class="light-text">Yesterday in <a href="/{{collection.stub}}">{{collection.name}}</a></span>
                </span>
            </div>
        </div>'
        
        

    constructor: (@type, @fields = {}) ->
        @fields.author ?= 'author'
        @fields.collection ?= 'collection'
        
        
        
    render: (data) =>
        author = data[@fields.author]
        collection = data[@fields.collection]
        assetUrl = data.author.getAssetUrl()
        switch @type
            when 'small'
                Authorship.smallTemplate { author, collection, assetUrl }
            else
                Authorship.template { author, collection, assetUrl }

    
exports.Authorship = Authorship


