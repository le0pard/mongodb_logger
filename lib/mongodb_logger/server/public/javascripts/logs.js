(function() {
  var MongodbLoggerJS;

  $(function() {
    return MongodbLoggerJS.init();
  });

  MongodbLoggerJS = {
    tail_logs_url: null,
    tail_log_started: false,
    log_info_offset: null,
    log_info_padding: 15,
    init: function() {
      var _this = this;
      $(document).ajaxStart(function() {
        return $('#ajax_loader').show();
      });
      $(document).ajaxStop(function() {
        return $('#ajax_loader').hide();
      });
      $('#tail_logs_link').live('click', function(event) {
        MongodbLoggerJS.tail_logs_url = $(event.target).attr('data-url');
        $('#tail_logs_block').addClass('started');
        MongodbLoggerJS.tail_logs(null);
        return false;
      });
      $('#tail_logs_stop_link').live('click', function(event) {
        MongodbLoggerJS.tail_log_started = false;
        $('#tail_logs_block').removeClass('started');
        return false;
      });
      $('.log_info').live('click', function(event) {
        var elm_obj, url;
        elm_obj = $(event.target);
        url = elm_obj.attr('data-url');
        if (!(url != null)) url = elm_obj.parents('tr').attr('data-url');
        if (url != null) {
          elm_obj.parents('table').find('tr').removeClass('current');
          elm_obj.parents('tr').addClass('current');
          $('#log_info').load(url);
        }
        return false;
      });
      $('div.filter-toggle').live('click', function(event) {
        return $('div.filter').slideToggle();
      });
      $('#add_more_filter').live('click', function(event) {
        var url;
        url = $(event.target).attr('href');
        $.ajax({
          url: url,
          success: function(data) {
            var content;
            content = $('<li></li>').html(data);
            return $('#more_filter_list').append(content);
          }
        });
        return false;
      });
      $('.close_more_filter').live('click', function(event) {
        $(event.target).parents('li').remove();
        return false;
      });
      $('li.message_tab').live('click', function(event) {
        var elm_obj, tab;
        elm_obj = $(event.target);
        tab = elm_obj.attr('data-tab');
        if (tab != null) {
          $('li.message_tab').removeClass('active');
          $('pre.tab_content').addClass('hidden');
          elm_obj.addClass('active');
          return $('.' + tab).removeClass('hidden');
        }
      });
      this.init_pjax();
      return this.init_on_pages();
    },
    init_pjax: function() {
      var _this = this;
      $('a[data-pjax]').pjax();
      $('body').bind('pjax:start', function() {
        return $('#ajax_loader').show();
      });
      return $('body').bind('pjax:end', function() {
        $('#ajax_loader').hide();
        MongodbLoggerJS.tail_log_started = false;
        if ($(window).scrollTop() > 100) {
          $('html, body').stop().animate({
            scrollTop: 0
          }, 'slow');
        }
        return MongodbLoggerJS.init_on_pages();
      });
    },
    init_on_pages: function() {
      var _this = this;
      $('pre code').each(function(i, e) {
        return hljs.highlightBlock(e, '  ');
      });
      if ($("#log_info").length > 0) {
        MongodbLoggerJS.log_info_offset = $("#log_info").offset();
        return $(window).scroll(function() {
          if ($(window).scrollTop() > MongodbLoggerJS.log_info_offset.top) {
            return $("#log_info").stop().animate({
              marginTop: $(window).scrollTop() - MongodbLoggerJS.log_info_offset.top + MongodbLoggerJS.log_info_padding
            });
          } else {
            return $("#log_info").stop().animate({
              marginTop: 0
            });
          }
        });
      }
    },
    tail_logs: function(count) {
      var url;
      url = MongodbLoggerJS.tail_logs_url;
      if (count != null) {
        url = MongodbLoggerJS.tail_logs_url + "/" + count;
      } else {
        MongodbLoggerJS.tail_log_started = true;
        count = 0;
      }
      if (MongodbLoggerJS.tail_log_started) {
        return $.ajax({
          url: url,
          dataType: "json",
          success: function(data) {
            var elements, fcallback;
            if (data.time) {
              $('#tail_logs_time').text(data.time);
              if (count !== data.count) {
                count = data.count;
                if ($("#db_collection_count").length > 0) {
                  $("#db_collection_count").text(count);
                }
                if ((data.content != null) && data.content.length > 0) {
                  elements = $(data.content);
                  elements.addClass('newlog');
                  $('#logs_list tr:first').after(elements).effect("highlight", {}, 1000);
                }
              }
            }
            if (MongodbLoggerJS.tail_log_started) {
              fcallback = function() {
                return MongodbLoggerJS.tail_logs(count);
              };
              return setTimeout(fcallback, 2000);
            }
          }
        });
      }
    }
  };

}).call(this);
