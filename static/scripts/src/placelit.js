// Generated by CoffeeScript 1.10.0
(function() {
  var PLMap;

  PLMap = (function() {
    function PLMap() {
      this.elements = {
        modals: {
          mapmodal: $('#mapmodal'),
          querymodal: $('#querymodal')
        }
      };
      this.path = window.location.pathname;
      this.search = this.parseQuery(window.location.search);
      this.scenes = window.SCENES;
    }

    PLMap.prototype.showModal = function(element) {
      return element.modal();
    };

    PLMap.prototype.isFiltered = function() {
      if ((this.path.indexOf('collections') === -1) && (this.path.indexOf('author') === -1) && (this.path.indexOf('title') === -1)) {
        console.log('isFiltered false');
        return false;
      }
      console.log('isFiltered true');
      return true;
    };

    PLMap.prototype.hasScenes = function() {
      return this.scenes && this.scenes.length > 0;
    };

    PLMap.prototype.selectMapView = function() {
      if (this.isFiltered() && this.hasScenes()) {
        console.log("this is a search =================");
        return new PlacingLit.Views.MapFilterView(this.scenes);
      }
      console.log("this is a default view ===============");
      return new PlacingLit.Views.MapCanvasView;
    };

    PLMap.prototype.closeFeatContent = function() {
      return $('#mapOverlay').hide();
    };

    PLMap.prototype.displayEmptyResultsError = function() {
      var alertMessage, author, author_path;
      author_path = '/map/filter/author/';
      author = decodeURIComponent(this.path.replace(author_path, ''));
      alertMessage = 'Whoa! No places found for ' + author + '. ';
      alertMessage += 'But that\'s ok!. Be the first to map this author. ';
      alertMessage += 'Click the map to add a book and author.';
      return alert(alertMessage);
    };

    PLMap.prototype.parseQuery = function(q) {
      var i, len, param, result, splitq, vals;
      result = {};
      splitq = q.split('&');
      for (i = 0, len = splitq.length; i < len; i++) {
        param = splitq[i];
        vals = param.split('=');
        result[vals[0]] = vals[1];
      }
      result;
      return console.log('parseQuery result: ' + JSON.stringify(result));
    };

    return PLMap;

  })();

  $(function() {
    var plmap, view;
    plmap = new PLMap();
    view = plmap.selectMapView();
    console.log('view created: ' + view.constructor.name);
    if (location.search === '?modal=1') {
      plmap.showModal(plmap.elements.modals.mapmodal);
    } else if (plmap.isFiltered()) {
      if (plmap.scenes && plmap.scenes.length > 0) {
        plmap.closeFeatContent();
        plmap.showModal(plmap.elements.modals.querymodal);
      } else {
        plmap.displayEmptyResultsError();
        if (history) {
          console.log("history should be cleared");
          history.replaceState(null, null, '/');
        }
      }
    }
    if (!Modernizr.input.placeholder) {
      view.handleInputAttributes();
    }
    return view.showInfowindowFormAtLocation();
  });

  $.ajax({
    url: "/blog/latest",
    success: (function(_this) {
      return function(data) {
        data = JSON.parse(data);
        $('#recent-blog-post-summary').html(data['newest_post_description']);
        $('#recent-blog-post-link').attr('href', data['newest_post_link']);
        $('#recent-blog-post-title').html(data['newest_post_title']);
        $('#recent-blog-post-published-date').html(data["newest_post_pub_date"]);
        return console.log();
      };
    })(this),
    error: (function(_this) {
      return function(err) {
        console.log("error requesting newest blog from server");
        return console.log(err);
      };
    })(this)
  });

  $.ajax({
    url: "/places/recent",
    dataType: "json",
    success: (function(_this) {
      return function(data) {
        return $('#newest_scene').html("<b>" + data[0]['location'] + "</b> from <i> " + data[0]['title'] + "</i> by " + data[0]['author']);
      };
    })(this),
    error: (function(_this) {
      return function(err) {
        return console.log("error: /places/recent - " + err);
      };
    })(this)
  });

  '$.ajax\n  url:"/collections/slq",\n  success: (data) =>\n    console.log("slq collection: ");\n    console.log(data);\n  error: (err) =>\n    console.log("error: /collections/slq - " + JSON.stringify(err) )\n';

}).call(this);
