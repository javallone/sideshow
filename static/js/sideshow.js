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

$('.add').live('pageinit', function(evt) {
    var page = $(evt.target);

    page.find('form').submit(function() {
        var form = $(this);

        $.mobile.showPageLoadingMsg();

        $.ajax({
            type: 'GET',
            url: form.attr('action'),
            data: form.serialize(),
            complete: function() {
                var id = form.find('[name="resource"]').val(),
                    movie_list = $('[data-movies-for="' + id + '"]');

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
