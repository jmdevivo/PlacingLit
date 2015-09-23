###
  author @ Will Acheson
  This class is modeled after app.coffe

  funcaitonality 1:
    My goal is to have a manipulatable google map widget on the mobile app
      A list view shows nearby placing lit scenes
      Then configure the map to only be loaded if a user clicks on a nearby event
        Then the map shows that location on the map
  functionality 2:
    Add new scenes by dragging the map to the location
      The center of the screen has a marker placed, this marker is not moveable
        -- except by dragging the map



###

window.PlacingLit =
  Models: {}
  Collections: {}
  Views: {}

###
  ????? TODO: figure out why i dont hate mvc
###

class PlacingLit.Collections.Locations extends Backbone.Collection
  console.log('placingLit.Collections.Locations model utilized:  /places/show route')
  model: PlacingLit.Models.Location

  url: '/places/show'

###
  Class for getting scene locations?
###
class PlacingLit.Models.Location extends Backbone.Model
  defaults:
    title: 'Put Title Here'
    author: 'Someone\'s Name goes here'

  url: '/places/add'

###
  View controller for the Google Map widget
  utilizies MarkerCluster for plotting (I think)
###
class PlacingLit.Views.MapCanvasView extends Backbone.View
  model: PlacingLit.Models.Location
  el: 'map_canvas'

  location: null

  gmap: null
  infowindows: []
  locations: null
  userInfowindow: null
  placeInfowindow: null
  userMapsMarker: null
  allMarkers: []
  initialMapView: true

  field_labels:
    place_name: 'location'
    scene_time: 'time'
    actors: 'characters'
    symbols: 'symbols'
    description: 'description'
    notes: 'notes'
    visits: 'visits'
    date_added: 'added'

  settings:
    zoomLevel:
      'wide' : 4
      'default': 5
      'close': 14
      'tight' : 21
      'increment' : 1
    markerDefaults:
      draggable: true
      animation: google.maps.Animation.DROP
      icon :'/img/redpin.png'
    maxTerrainZoom: 15



  mapOptions:
    #TODO styled maps?
    #https://developers.google.com/maps/documentation/javascript/styling#creating_a_styledmaptype
    zoom: 8
    #google.maps.MapTypeId.SATELLITE | ROADMAP | HYBRID
    mapTypeId: google.maps.MapTypeId.ROADMAP
    mapTypeControl: true
    mapTypeControlOptions:
      style: google.maps.MapTypeControlStyle.DROPDOWN_MENU
      position: google.maps.ControlPosition.TOP_RIGHT
    draggable: true
    maxZoom: 20
    minZoom: 2
    zoomControl: true
    zoomControlOptions:
      style: google.maps.ZoomControlStyle.DEFAULT
       # position: google.maps.ControlPosition.TOP_LEFT
      position: google.maps.ControlPosition.LEFT_CENTER
    panControlOptions:
       # position: google.maps.ControlPosition.TOP_LEFT
      position: google.maps.ControlPosition.RIGHT_CENTER


  # TODO: we know this is called, but what next?
  console.log('MapCanvasView class called')


  initialize: (scenes) ->
    console.log('MapCanvasView.initialize(scenes) executed.')
    @collection ?= new PlacingLit.Collections.Locations()
    @listenTo @collection, 'all', @render
    @collection.fetch()
    # setup handler for geocoder searches
    #@suggestAuthors()
    @googlemap()
    @positionMap()
    @attachNewSceneHandler()
    @attachSearchHandler()


    render: (event) ->
      console.log("MapCanvasView..render(event) executed")
      @mapWithMarkers() if event is 'sync'


  googlemap: ()->
    return @gmap if @gmap?
    map_elem = document.getElementById(@$el.selector)
    console.log("mobapp:: googlemap() mapOptions: " + JSON.stringify(@mapOptions))
    @gmap = new google.maps.Map(map_elem, @mapOptions)
    @mapCenter = @gmap.getCenter()
    #google.maps.event.addListener(@gmap, 'bounds_changed', @handleViewportChange)
    #@gmap.MapOptions.draggable = true
    return @gmap

  handleViewportChange: (event) =>
    console.log("MapCanvasView.handleViewportChange(event) was executed")
    center = @gmap.getCenter()
    centerGeoPt =
      lat: center[Object.keys(center)[0]]
      lon: center[Object.keys(center)[1]]
    if @gmap.getZoom() >= @settings.maxTerrainZoom
      @gmap.setMapTypeId(google.maps.MapTypeId.ROADMAP)
    else
      @gmap.setMapTypeId(google.maps.MapTypeId.TERRAIN)

  positionMap: () ->
    console.log("mobileapp positionMap is called")
    if window.CENTER?
      mapcenter = new google.maps.LatLng(window.CENTER.lat, window.CENTER.lng)
      @gmap.setCenter(mapcenter)
      if (window.location.pathname.indexOf('collections') != -1)
        @gmap.setZoom(@settings.zoomLevel.wide)
      else
        @gmap.setZoom(@settings.zoomLevel.default)
      if (window.location.pathname.indexOf('author') != -1)
        @gmap.setZoom(@settings.zoomLevel.wide)
    else
      usaCoords =
        lat: 39.8282
        lng: -98.5795
      usacenter = new google.maps.LatLng(usaCoords.lat, usaCoords.lng)
      if navigator.geolocation
        navigator.geolocation.getCurrentPosition((position) =>

          userCoords =
            lat: position.coords.latitude
            lng: position.coords.longitude
          @gmap.setCenter(userCoords)
          console.log('mobileapp.js :: positionMap() lat: ' + position.coords.latitude + ' long: ' + position.coords.longitude)
          @location = userCoords
        )
      else
        @gmap.setCenter(usacenter)
      @gmap.setZoom(8)
    if window.PLACEKEY?
      windowOptions = position: mapcenter
      @openInfowindowForPlace(window.PLACEKEY, windowOptions)
    @initialMapView = false

  handleMapClick: (event) ->
    @setUserMapMarker(@gmap, event.latLng)

  setUserPlaceFromLocation: (location) ->
    console.log("MapCanvasView.setuserPlaceFromLocation(location) executed")
    console.log("--location: " + location)
    #@userPlace = locationclass PlacingLit.Models.Location extends Backbone.Model
    @userPlace = PlacingLit.Models.Location extends Backbone.Model
    defaults:
      title: 'Put Title Here'
      author: 'Someone\'s Name goes here'
    url: '/places/add'

  # This populates suggestions for authors
  # during searches, unsure why it is included in MapCanvasView
  # TODO: provide necessary elements on the front end to support this related to Search Handler
  suggestAuthors: (author_data) ->
    parent = document.getElementById('authorsSearchList')
    $(parent).empty()
    $(parent).show()
    searchTxt = $('#gcf').val()
    if searchTxt != ""
      for author in author_data
        if author.indexOf(searchTxt) > -1
          li = document.createElement('li')
          li.className = 'searchResultText'
          li.innerHTML = author
          parent.appendChild(li)
          if $(parent).children().length > 5
            break;
      $('.searchResultText').click(() ->
        windowLoc = window.location.protocol + '//' + window.location.host
        window.location.href = (windowLoc + "/map/filter/author/" + @innerHTML)
        )


  # TODO: provide necessary elements on the front end to support this Search Handler
  attachSearchHandler: ->
    $.ajax
      url: "/places/authors"
      success: (authors) =>
        $.ajax
          url: "/places/titles"
          success: (titles) =>
            $('#gcf').on('keydown', (event) =>
                  author_data = []
                  title_data = []
                  console.log titles
                  $.each authors, (key, value) =>
                    author_data.push(value.author.toString())
                  $.each titles, (key, value) =>
                    title_data.push(value.title.toString())
                  @hideOverlay()
                  $('.geosearchResults').show()
                  #$('#info-overlay').show()
                  @suggestAuthors(author_data)
                  @suggestTitles(title_data)
                  @populateSuggestedSearches(authors, titles)
              )
            $('#search').on 'click', (event) =>
              #$('#info-overlay').show()
              @populateSuggestedSearches()

  # This defines the action of the add scene button
  # TODO: provide necessary elements on the front end to support this add scene handler
  attachNewSceneHandler: ->
    console.log "The attach new scene handler is firing"
    $('#new_scene_submit_btn').click( () =>
      console.log("new scene button action listenr is assigned")
      @addPlace()
      )
  showInfowindowFormAtLocation: (map, marker, location) ->
    @closeInfowindows()
    #@userInfowindow = @infowindow()
    #@userInfowindow.setContent(document.getElementById('iwcontainer').innerHTML)
    #@userInfowindow.setPosition(location)
    #@userInfowindow.open(map, @userMapsMarker)
    if not Modernizr.input.placeholder
      google.maps.event.addListener(@userInfowindow, 'domready', () =>
      @clearPlaceholders()
      )
    $('#map_canvas').find('#guidelines').on 'click', (event) =>
      $('#helpmodal').modal()
    google.maps.event.addListenerOnce @userInfowindow, 'closeclick', () =>
      @userMapsMarker.setMap(null)

  closeInfowindows: ->
    iw.close() for iw in @infowindows

  reportUserLocationToServer: ->
    console.log("Tryna talk to the server!")
    $.ajax
      url: '/mobile/closeby'
      data: @location
      success: (data) =>
        console.log(data)
