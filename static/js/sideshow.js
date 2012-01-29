$('[data-role="page"], [data-role="dialog"]').live('pageinit', function(evt) {
    var page = $(evt.target);

    page.find('a[href^="/control/"]').click(function() {
        $.mobile.showPageLoadingMsg();

        $.ajax({
            type: 'GET',
            url: $(this).attr('href'),
            complete: function() {
                $.mobile.hidePageLoadingMsg();
            }
        });

        return false;
    });
});

$('.program').live('pageinit', function(evt) {
    var page = $(evt.target);

    page.find('[data-movies-for]')
        .bind('create', function() {
            $(this).find('a[data-hold-href]').bind('taphold', function() {
                $.mobile.changePage($(this).data('hold-href'));
                return false;
            });
        })
        .trigger('create');
});

$('.search').live('pageinit', function(evt) {
    var page = $(evt.target),
        results = page.find('.results');

    page.find('form').submit(function() {
        var form = $(this);

        $.mobile.showPageLoadingMsg();

        $.ajax({
            type: 'GET',
            url: form.attr('action'),
            data: form.serialize(),
            complete: function(xhr) {
                $.mobile.hidePageLoadingMsg();
                results.html(xhr.responseText);
                results.trigger('create');
            }
        });

        return false;
    });
});

$('.add, .modify').live('pageinit', function(evt) {
    var page = $(evt.target);

    function refreshMovieList(id, complete) {
        var movie_list = $('[data-movies-for="' + id + '"]');

        $('.movies').remove();

        $.ajax({
            type: 'GET',
            url: '/movies' + id,
            complete: function(xhr) {
                movie_list.html(xhr.responseText);
                movie_list.trigger('create');

                $.mobile.hidePageLoadingMsg();
                page.dialog('close');
            }
        });
    }

    page.find('a[data-method="ajax"]').click(function(evt) {
        var link = $(this);

        $.mobile.showPageLoadingMsg();

        $.ajax({
            type: 'GET',
            url: link.attr('href'),
            complete: function() {
                var id = link.data('resource');

                refreshMovieList(id, function() {
                    $.mobile.hidePageLoadingMsg();
                    page.dialog('close');
                });
            }
        });

        return false;
    });

    page.find('form').submit(function() {
        var form = $(this);

        $.mobile.showPageLoadingMsg();

        $.ajax({
            type: 'GET',
            url: form.attr('action'),
            data: form.serialize(),
            complete: function() {
                var id = form.find('[name="resource"]').val();

                refreshMovieList(id, function() {
                    $.mobile.hidePageLoadingMsg();
                    page.dialog('close');
                });
            }
        });

        return false;
    });
});

$('.settings').live('pageinit', function(evt) {
    var page = $(evt.target);

    page.find('form').submit(function() {
        var form = $(this);

        $.mobile.showPageLoadingMsg();

        $.ajax({
            type: 'GET',
            url: form.attr('action'),
            data: form.serialize(),
            complete: function() {
                $.mobile.hidePageLoadingMsg();
                page.dialog('close');
            }
        });

        return false;
    });

    page.find('a[href="/refresh"], a[href="/flush"]').click(function() {
        $.mobile.showPageLoadingMsg();

        $.ajax({
            url: $(this).attr('href'),
            complete: function() {
                $.mobile.hidePageLoadingMsg();
                page.dialog('close');
            }
        });

        return false;
    });
});
