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
      console.log('placelit.coffee :: search object: ' + JSON.stringify(this.search));
      this.scenes = window.SCENES;
      console.log('placelit.coffee :: scenes: ' + this.scenes);
    }

    PLMap.prototype.showModal = function(element) {
      return element.modal();
    };

    PLMap.prototype.isFiltered = function() {
      if ((this.path.indexOf('collections') === -1) && (this.path.indexOf('author') === -1) && (this.path.indexOf('title') === -1)) {
        return false;
      }
      return true;
    };

    PLMap.prototype.hasScenes = function() {
      return this.scenes && this.scenes.length > 0;
    };

    PLMap.prototype.selectMapView = function() {
      if (this.isFiltered() && this.hasScenes()) {
        return new PlacingLit.Views.MapFilterView(this.scenes);
      }
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
      return result;
    };

    return PLMap;

  })();

  $(function() {
    var plmap, view;
    plmap = new PLMap();
    view = plmap.selectMapView();
    console.log('placelit.coffee :: view created: ' + view.constructor.name);
    if (location.search === '?modal=1') {
      plmap.showModal(plmap.elements.modals.mapmodal);
    } else if (plmap.isFiltered()) {
      if (plmap.scenes && plmap.scenes.length > 0) {
        plmap.closeFeatContent();
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
        console.log("This is the latest blog resource handler output");
        console.log("data typeof:     " + typeof data);
        data = JSON.parse(data);
        console.log("data:     " + JSON.stringify(data));
        console.log("description   " + data['newest_post_description']);
        $('#recent-blog-post-summary').html(data['newest_post_description']);
        console.log("link:    " + data['newest_post_link']);
        $('#recent-blog-post-link').attr('href', data['newest_post_link']);
        console.log("title    " + data['newest_post_title']);
        return $('#recent-blog-post-title').html(data['newest_post_title']);
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

  '$.ajax\n  url: "/places/near/1",\n  dataType: "json",\n  success: (data) =>\n    console.log("Success!  ")\n    console.log(data)\n    console.log(JSON.stringify(data))\n  error: (err) =>\n    console.log(\'Error: \' + err)';

}).call(this);
