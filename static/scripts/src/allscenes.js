// Generated by CoffeeScript 1.9.3
(function() {
  var AllScenes,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  AllScenes = (function() {
    function AllScenes(key) {
      this.key = key;
      this.deletePlace = bind(this.deletePlace, this);
      this.editPlace = bind(this.editPlace, this);
      this.detachEvents = bind(this.detachEvents, this);
      if (this.key == null) {
        this.key = window.location.search.split("=")[1];
      }
      this.list = new PlacingLit.Views.Allscenes();
      this.elements = {
        inputs: $("#editform :input"),
        editButton: $("#editplacebutton"),
        deleteButton: $("#deleteplacebutton")
      };
    }

    AllScenes.prototype.apiEndpoint = function() {
      return "/admin/edit?key=" + this.key;
    };

    AllScenes.prototype.post = function(data) {
      return $.ajax({
        url: this.apiEndpoint(),
        type: "POST",
        data: data
      });
    };

    AllScenes.prototype.destroy = function(data) {
      return $.ajax({
        url: this.apiEndpoint(),
        type: "DELETE",
        data: data
      });
    };

    AllScenes.prototype.attachEvents = function() {
      this.elements.editButton.on("click.allscenes", this.editPlace);
      this.elements.deleteButton.on("click.allscenes", this.deletePlace);
      return this;
    };

    AllScenes.prototype.detachEvents = function(data) {
      this.elements.deleteButton.off('click.allscenes').text(data);
      return data;
    };

    AllScenes.prototype.buildDataFromElements = function() {
      return _(this.elements.inputs.serializeArray()).chain().map(function(field) {
        return [field.name, field.value];
      }).object().value();
    };

    AllScenes.prototype.editPlace = function() {
      return this.post(this.buildDataFromElements()).then(this.detachEvents);
    };

    AllScenes.prototype.deletePlace = function() {
      return this.destroy().then(this.detachEvents).then((function(_this) {
        return function() {
          return _this.elements.editButton.remove();
        };
      })(this));
    };

    return AllScenes;

  })();

  $(function() {
    return new AllScenes().attachEvents();
  });

}).call(this);
