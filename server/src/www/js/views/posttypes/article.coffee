class Article

    constructor: (@post) ->
        $(document).ready =>
            @attachEvents()
            mode = Fora.getUrlParams 'mode'
            if mode is 'edit'
                @onEdit()
        
        
        
    attachEvents: =>
        $('button.edit').click @onEdit



    onEdit: =>
        $('.edit-options').hide()
        
        $('.page-wrap').prepend '
            <div class="nav buttons">
                <ul>
                </ul>
            </div>'

        $('.page-wrap .nav.buttons ul').append '<li><button>Delete</button></li>'
        if @post.state is 'published'
            $('.page-wrap .nav.buttons ul').append '<li><button>Cancel</button></li>'
        $('.page-wrap .nav.buttons ul').append '<li><button class="positive">Publish Post</button></li>'
        
        editor = new Fora.Editing.Editor()
        editor.editPage if @post.title then '.content' else 'h1'
    

window.Fora.Views.PostTypes.Article = Article
