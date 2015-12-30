
window.PlacingLit =
  Models: {}
  Collections: {}
  Views: {}


class PlacingLit.Models.Location extends Backbone.Model
  defaults:
    title: 'Put Title Here'
    author: 'Someone\'s Name goes here'

  url: '/places/add'


class PlacingLit.Models.Metadata extends Backbone.Model
  url: '/places/count'

  initialize: ->

class PlacingLit.Collections.Locations extends Backbone.Collection
  #console.log('placingLit.Collections.Locations model utilized:  /places/show route')
  model: PlacingLit.Models.Location

  url: '/places/show'


class PlacingLit.Collections.NewestLocations extends Backbone.Collection
  model: PlacingLit.Models.Location

  url :'/places/recent'


class PlacingLit.Collections.NewestLocationsByDate extends Backbone.Collection
  model: PlacingLit.Models.Location

  url :'/places/allbydate'

# Added by Will Acheson for map speedup, limited place loading
class PlacingLit.Collections.LocationsNear extends Backbone.Collection
  model: PlacingLit.Models.Location

  url:'/places/near'


class PlacingLit.Views.MapCanvasView extends Backbone.View
  model: PlacingLit.Models.Location
  el: 'map_canvas'

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
      draggable: false
      animation: google.maps.Animation.DROP
      icon :'/img/redpin.png'
    maxTerrainZoom: 15


  mapOptions:
    #TODO styled maps?
    #https://developers.google.com/maps/documentation/javascript/styling#creating_a_styledmaptype
    zoom: 8
    #google.maps.MapTypeId.SATELLITE | ROADMAP | HYBRID
    mapTypeId: google.maps.MapTypeId.ROADMAP
    mapTypeControlOptions:
      style: google.maps.MapTypeControlStyle.DROPDOWN_MENU
      position: google.maps.ControlPosition.TOP_RIGHT
    maxZoom: 20
    minZoom: 2
    zoomControl: true
    zoomControlOptions:
      style: google.maps.ZoomControlStyle.DEFAULT
      # position: google.maps.ControlPosition.TOP_LEFT
      position: google.maps.ControlPosition.LEFT_CENTER
    panControlOptions:
      # position: google.maps.ControlPosition.TOP_LEFT
      position: google.maps.ControlPosition.LEFT_CENTER



  initialize: (scenes) ->
    @getRecentBlog();
    @collection ?= new PlacingLit.Collections.Locations()
    @listenTo @collection, 'all', @render

    # testing placesNear
    if navigator.geolocation
      position = navigator.geolocation.getCurrentPosition(@getPlacesNearController)
    @collection.fetch()
    # setup handler for geocoder searches
    @suggestAuthors()
    @attachNewSceneHandler()
    @attachSearchHandler()
    @linkMagnifyClickGcf() # make clicking #search (magnifying glass) press enter in #gcf (search bar)
    # crazy idea to make share links load to the scene card
    @isShareLink();

  # if true, then map should load right to this scene card
  isShareLink: () ->
    pathname = window.location.pathname;
    if (pathname.indexOf("map") > -1 and pathname.indexOf("filter") > -1 and pathname.indexOf("id") > -1)
      mapcenter = new google.maps.LatLng(window.CENTER.lat, window.CENTER.lng)
      @gmap.setCenter(mapcenter);



      # dbkey and window options are inparam
      #@openInfowindowForPlace(window.)


  getPlacesNearController: (position) =>

    console.log("requesting: " + '/places/near?lat=' + -19.155320 + "&lon=" + 30.013956)
    #-19.155320 30.013956
    $.ajax
      #url:'/places/near?lat=' + position.coords.latitude + "&lon=" + position.coords.longitude
      url:'/places/near?lat=' + -19.155320 + "&lon=" + 30.013956
      dataType:"json"
      success: (data) =>
        console.log("call to /places/near successful")
        console.log("near places "  + JSON.stringify(data))
      error: (err) =>
        console.log("call to /places/near failed")
        console.log("error: " + err)


  getRecentBlog: () =>
    # TODO: move to app.coffe function, call in initalization
    $.ajax
      url: "/blog/latest",
      success: (data) =>
        data = JSON.parse(data)
        $('#recent-blog-post-summary').html(data['newest_post_description']);
        $('#recent-blog-post-link').attr('href', data['newest_post_link']);
        $('#recent-blog-post-title').html(data['newest_post_title']);
        $('#recent-blog-post-published-date').html(data["newest_post_pub_date"]);
        console.log();
      error: (err) =>
        console.log("error requesting newest blog from server")
        console.log(err)


  render: (event) ->
    @mapWithMarkers() if event is 'sync'

  googlemap: ()->
    # GoogleMaps API documentation:  Very helpful
    # https://developers.google.com/maps/documentation/javascript/reference
    return @gmap if @gmap?
    map_elem = document.getElementById(@$el.selector)
    @gmap = new google.maps.Map(map_elem, @mapOptions)
    @mapCenter = @gmap.getCenter()
    google.maps.event.addListener(@gmap, 'bounds_changed', @handleViewportChange)
    return @gmap

  handleViewportChange: (event) =>
    center = @gmap.getCenter()
    centerGeoPt =
      lat: center[Object.keys(center)[0]]
      lon: center[Object.keys(center)[1]]
    if @gmap.getZoom() >= @settings.maxTerrainZoom
      @gmap.setMapTypeId(google.maps.MapTypeId.ROADMAP)
    else
      @gmap.setMapTypeId(google.maps.MapTypeId.TERRAIN)

  closeNewEntry: () ->

    $('#new_entry').hide()

  updateCollection: (event) ->
    center = @gmap.getCenter()
    centerGeoPt =
      lat: center[Object.keys(center)[0]]
      lng: center[Object.keys(center)[1]]
    zoom = @gmap.getZoom()
    console.log('pan/zoom idle', centerGeoPt, zoom)
    if window.CENTER?
      console.log(window.CENTER)
      console.log(Math.abs(window.CENTER.lat - centerGeoPt.lat))
      console.log(Math.abs(window.CENTER.lng - centerGeoPt.lng))
    else
      window.CENTER = centerGeoPt

    query = '?lat=' + centerGeoPt.lat + '&lon=' + centerGeoPt.lng
    # collection_url seems like it may be how you call the /places/near route
    collection_url = '/places/near' + query
    update = false
    if Math.abs(window.CENTER.lat - centerGeoPt.lat) > 5
      update = true
    if Math.abs(window.CENTER.lng - centerGeoPt.lng) > 5
      update = true

    # window.CENTER = centerGeoPt
    if update
      window.CENTER = centerGeoPt
      @collection.reset(collection_url)

  marker: ->
    @placeInfowindow.close() if @placeInfowindow?
    return new google.maps.Marker()

  infowindow: ->
    #return new google.maps.InfoWindow()
    @closeInfowindows() if @infowindows.length
    iw = new google.maps.InfoWindow()
    @infowindows.push(iw)
    return iw

  closeInfowindows: ->
    iw.close() for iw in @infowindows

  mappoint: (latitude, longitude)->
    console.log("MapCanvasView called")
    console.log("--lat: " + latitude)
    console.log("--lng: " + longitude)

    return new google.maps.LatLng(latitude, longitude)

  markerFromMapLocation: (map, location)->
    console.log("markerFromMapLocation")
    markerSettings =
      position: location
      map: map
      animation: google.maps.Animation.DROP
      draggable: true
    return new google.maps.Marker(markerSettings)

  updateInfoWindow: (text, location, @map = @googlemap('hpmap')) ->
    infowindow = @infowindow()
    infowindow.setContent(text)
    infowindow.setPosition(location)
    infowindow.open(map)

  setUserPlaceFromLocation: (location) ->
    console.log("MapCanvasView.setuserPlaceFromLocation(location) executed")
    console.log("--location: " + location)
    @userPlace = locationclass PlacingLit.Models.Location extends Backbone.Model
  defaults:
    title: 'Put Title Here'
    author: 'Someone\'s Name goes here'

  url: '/places/add'

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


  clearPlaceholders: () ->
    $('#title').one('keypress', ()-> $('#title').val(''))
    $('#author').one('keypress', ()-> $('#author').val(''))
    $('#place_name').one('keypress', ()-> $('#place_name').val(''))
    $('#date').one('keypress', ()-> $('#date').val(''))
    $('#actors').one('keypress', ()-> $('#actors').val(''))
    $('#symbols').one('keypress', ()-> $('#symbols').val(''))
    $('#scene').one('keypress', ()-> $('#scene').val(''))
    $('#notes').one('keypress', ()-> $('#notes').val(''))
    $('#image_url').one('keypress', ()-> $('#image_url').val(''))

  clearMapMarker: (marker) ->
    marker.setMap(null)
    marker = null

  suggestTitles: (title_data) ->
    console.log("suggestTitles")
    parent = document.getElementById('bookSearchList')
    $(parent).empty()
    $(parent).show()
    searchTxt = $('#gcf').val()
    if searchTxt != ""
      for title in title_data
        if title.indexOf(searchTxt) > -1
          li = document.createElement('li')
          li.className = 'searchResultText searchResultTitleText'
          li.innerHTML = title
          parent.appendChild(li)
          if $(parent).children().length > 5
            break;
      $('.searchResultTitleText').click(() ->
        windowLoc = window.location.protocol + '//' + window.location.host
        window.location.href = (windowLoc + "/map/filter/title/" + @innerHTML)
        )

  suggestAuthors: (author_data) ->
    #console.log("suggestAuthors")
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

    #$('#map_canvas').find('#author').typeahead({source: author_data})

  markersForEachScene: (markers) ->
    console.log("markersForEachScene")
    markers.each (model) => @dropMarkerForStoredLocation(model)

  markerArrayFromCollection: (collection) ->
    return (@buildMarkerFromLocation(model) for model in collection.models)


  updateInfoOverlay: (info) ->


  markerClustersForScenes: (locations) ->
    cluster_options =
      minimumClusterSize: 5
    allMarkerCluster = new MarkerClusterer(@gmap, locations, cluster_options)

  hideMarkers: =>
    marker.setMap(null) for marker in @allMarkers

  showMarkers: =>
    marker.setMap(@gmap) for marker in @allMarkers

  mapWithMarkers: () ->
    @gmap ?= @googlemap()
    @allMarkers = @markerArrayFromCollection(@collection)

    #console.log("all markers!!!!!"  + @allMarkers)
    # @markersForEachScene(@collection)
    @markerClustersForScenes(@allMarkers)
    @positionMap()
    @isUserLoggedIn( =>
      $('#addscenebutton').on('click', @handleAddSceneButtonClick)
      $('#addscenebutton').show()
    )

    # $('#hidemarkers').on('click', @hideMarkers)
    # $('#showmarkers').on('click', @showMarkers)

  positionMap: () ->
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
          #console.log("app.coffee :: positionMap() User coordinates!!  ")
          #console.log('lat: ' + position.coords.latitude + ' long: ' + position.coords.longitude)
        )
      else
        @gmap.setCenter(usacenter)
      @gmap.setZoom(8)

      #console.log(JSON.stringify(@gmap));

      # What is this doing?  seems to hav ea global PLACEKEY which could be causing
      # our problem with non-refreshing scene windows
    '''
    if window.PLACEKEY?
      windowOptions = position: mapcenter
      @openInfowindowForPlace(window.PLACEKEY, windowOptions)
    @initialMapView = false
    '''

  handleMapClick: (event) ->
    @setUserMapMarker(@gmap, event.latLng)

  handleAddSceneButtonClick: =>
    #@closeInfowindows() if @infowindows.length

    $('#entry-image').hide()
    $('.entry').hide()
    $('#tabs').hide()
    $('.new_scene_section').hide()
    $('#new_scene_book_info').show()
    @setUserMapMarker(@gmap, @gmap.getCenter())
    $('#info-overlay').show()
    $('#new_entry').show()
    $('.leave_new_scene_form').click(()->
      $('#info-overlay').hide()
      $('.entry').hide())
    # $('#addscenebutton').hide()
    # marker.setMap(null) for marker in @allMarkers

  setUserMapMarker: (map, location) ->
    @userMapsMarker.setMap(null) if @userMapsMarker?
    @userInfowindow.close() if @userInfowindow?
    @userMapsMarker = @markerFromMapLocation(map, location)
    @userMapsMarker.setMap(map)
    google.maps.event.addListenerOnce @userMapsMarker, 'click', (event) =>
      @isUserLoggedIn(@dropMarkerForNewLocation)
    @showUserMarkerHelp()

  showUserMarkerHelp: ->
    if @userMapsMarker
      loginWindowPosition = @userMapsMarker.getPosition()
      @closeInfowindows()
      @userInfowindow = @infowindow()
      content = '<div id="usermarker">'
      content += '<div>Drag this marker to place.<br>'
      content += 'Click the marker to add the scene</div></div>'
      @userInfowindow.setContent(content)
      @userInfowindow.setPosition(loginWindowPosition)
      @userInfowindow.open(@gmap, @userMapsMarker)
      google.maps.event.addListenerOnce @userInfowindow, 'closeclick', () =>
        @userMapsMarker.setMap(null)

  isUserLoggedIn: (callback) ->
    $.ajax
      datatype: 'json',
      url: '/user/status',
      success: (data) =>
        if data.status == 'logged in'
          callback.call(this)
        else
          $('#addscenebutton').click(() -> window.location.href = $('#loginlink').attr('href'))

  showLoginInfoWindow: () ->
    if @userMapsMarker
      loginWindowPosition = @userMapsMarker.getPosition()
    else
      loginWindowPosition = @gmap.getCenter()
    @closeInfowindows()
    @userInfowindow = @infowindow()
    content = '<div id="usermarker">'
    content += '<div>You must be logged in to update content.</div><br>'
    login_url = document.getElementById('loginlink').href
    content += '<a href="' + login_url + '"><button>log in</button></a></p>'
    content += '</div>'
    @userInfowindow.setContent(content)
    @userInfowindow.setPosition(loginWindowPosition)
    @userInfowindow.open(@gmap, @userMapsMarker)
    google.maps.event.addListener @userInfowindow, 'closeclick', () =>
      @userMapsMarker.setMap(null)

  dropMarkerForNewLocation: () ->
    location = @userMapsMarker.getPosition()
    @showInfowindowFormAtLocation(@gmap, @userMapsMarker, location)
    @setUserPlaceFromLocation(location)
    @handleInfowindowButtonClick()
    #@suggestTitles()
    #@suggestAuthors()


  updateInfowindowWithMessage: (infowindow, response, refresh) ->
    console.log('new marker', response, refresh)
    textcontainer = '<div id="thankswindow">' + response.message + '</div>'
    $('#new_scene_submit').append(textcontainer)
    if refresh
      google.maps.event.addListenerOnce infowindow, 'closeclick', () =>
        @userMapsMarker.setMap(null)
        @showUpdatedMap()

  showUpdatedMapWithNewScene: (scene) ->


  showUpdatedMap: () ->
    maps = new MapCanvasView

  handleInfowindowButtonClick : ()->
    $addPlaceButton = $('#new_scene_submit_btn')
    $addPlaceButton.on('click', @addPlace) if $addPlaceButton?

  getFormValues: () ->
    $form = $('#new_scene_form')
    form_data =
      title: $form.find('#new_scene_title').val()
      author: $form.find('#new_scene_author').val()
      place_name: $form.find('#new_scene_place_name').val()
      # date: $('#date').val()
      # actors: $('#actors').val()
      # symbols: $('#symbols').val()
      scene: $form.find('#new_scene_scene').val()
      notes: $form.find('#new_scene_notes').val()
      image_url: $form.find('#image_url').val()
      check_in: $form.find('#new_scene_check_in').prop('checked')
    form_data.latitude = @userPlace.lat()
    form_data.longitude = @userPlace.lng()
    #console.log form_data
    return form_data

  isFormComplete: (form_data) ->
    required_fields = ['title', 'author', 'place_name', 'scene', 'notes']
    completed_entry = true
    @missing_fields = ''
    for field in required_fields
      if form_data[field].length == 0
        field_name = field.charAt(0).toUpperCase()
        field_name += field.substr(1).toLowerCase()
        field_name = field_name.replace('_', ' ')
        @missing_fields += 'Missing ' + field_name + '.</br>'
        completed_entry = false
    return completed_entry

  addPlace: () =>
    console.log "addplace is firing"
    form_data = @getFormValues()
    if @isFormComplete(form_data)
      msg = '<span>adding... please wait...</span>'
      $('#map_canvas .infowindowform').find('#addplacebutton').replaceWith(msg)
      location = new PlacingLit.Models.Location()
      status = location.save(
        form_data,
          error: (model, xhr, options) =>
            console.log('add place error', model, xhr, options)
          success: (model, response, options) =>
            @updateInfowindowWithMessage(@userInfowindow, response, true)
      )
    else
      error_msg = '<p>Close this window and click the marker to start over. <br>
                  Fill out some of these fields so we can add your scene. <br>
                  Thanks.</p>'
      response =
        message: @missing_fields + error_msg
      @updateInfowindowWithMessage(@userInfowindow, response, false)
      return false

  geocoderSearch: () ->
    address = document.getElementById('gcf').value
    if address
      geocoder = new google.maps.Geocoder()
      geocoder.geocode({'address':address}, (results, status) =>
        if (status == google.maps.GeocoderStatus.OK)
          position = results[0].geometry.location
          @gmap.setCenter(position)
          @gmap.setZoom(@settings.zoomLevel.default)
          # @setUserMapMarker(@gmap, position)
        else
          alert("geocode was not successful: " + status)
      )

  populateSuggestedSearches: (authors, titles) ->
    console.log("populateSuggestedSearches")
    @hideOverlay()
    searchTxt = document.getElementById('gcf').value
    #@populateSuggestedAuthors(searchTxt)
    #@populateSuggestedTitles(searchTxt)
    if searchTxt
      geocoder = new google.maps.Geocoder()
      geocoder.geocode({'address': searchTxt}, (results, status) =>
        if(status == google.maps.GeocoderStatus.OK)
          console.log("how many results are returned? ")
          console.log("results type: " + typeof results )
          console.log("length of results: " + _.size(results))
          parent = document.getElementById('locationsSearchList')
          $(parent).empty()
          numRes = if results.length > 5 then 4 else results.length
          for i in [0 .. numRes]
            child = @createSearchElement(results[i])
            parent.appendChild(child)
        else if(status == google.maps.GeocoderStatus.ZERO_RESULTS)
          console.log "No Locations found, try rephrasing search"
        else
          alert("geocode was not successful: " + status)
      )

  hideOverlay: () ->
      overlay = document.getElementById("mapOverlay")
      overlay.style.display = 'none'

  populateSuggestedAuthors: (searchTxt) ->

    console.log("Populate Suggested Authors: " , searchTxt)
    if searchTxt
      query = searchTxt.replace(/ /, "%20")
      $.ajax
        url: "/places/authors/" + query
        success: (data) =>
          parent = document.getElementById('authorsSearchList')
          $(parent).empty
          i=0
          for author in data
            if i > 5
              break
            location = new google.maps.LatLng(author.scene_location.latitude, author.scene_location.longitude)
            name = author.author
            li = document.createElement('li')
            li.className = 'searchResultText'
            li.innerHTML = name
            li.data-location = location
            li.addEventListener('click', () =>
              @collection.fetch()
              @gmap.setCenter(location)
              @gmap.setZoom(@settings.zoomLevel.default)
            )
            parent.appendChild(li)
            i++

        error: (err) ->
          console.log err

  populateSuggestedTitles: (searchTxt) ->
    if searchTxt
      query = searchTxt.replace(/ /, "")
      $.ajax
        url: "/places/titles/" + query
        success: (data) =>
          parent = document.getElementById('bookSearchList')
          console.log "PopulateSuggestedTitles is firing"
          $(parent).empty
          i=0
          for title in data
            if i > 5
              break
            li = document.createElement('li')
            li.className = 'searchResultText'
            location = new google.maps.LatLng(title.latitude, title.longitude)
            li.innerHTML = title.title
            li.addEventListener('click', () =>
              @gmap.setCenter(location)
              @gmap.setZoom(@settings.zoomLevel.default)
            );
            parent.appendChild(li)
            i++


        error: (err) ->
          console.log err

  null_function: () =>
    return null

  createSearchElement: (element) ->
    console.log("CreateSearchElement")
    location = element.geometry.location
    name = element.formatted_address
    li = document.createElement('li')
    li.innerHTML = name
    li.data-location = location
    li.addEventListener('click', () =>
      @gmap.setCenter(location)
      @gmap.setZoom(@settings.zoomLevel.default)
    )
    li

  # initial function that handles author / place searches
  attachSearchHandler: ->
    $.ajax
      url: "/places/authors"
      success: (authors) =>
        $.ajax
          url: "/places/titles"
          success: (titles) =>
            $('#gcf').on('keydown', (keycode, event) =>
              if keycode.which==13
                console.log("Enter key pressed in #gcf")
                author_data = []
                title_data = []
                $.each authors, (key, value) =>
                  author_data.push(value.author.toString())
                $.each titles, (key, value) =>
                  title_data.push(value.title.toString())
                #console.log("author data: " + author_data);
                #console.log("title data " + title_data );
                @hideOverlay()
                #$('.geosearchResults').show() # this is the search suggestsion dropdown
                $('.geosearchResults').attr('style','display: block !important;')
                $('#mapcontainer').click ->
                  $('.geosearchResults').hide();
                @suggestAuthors(author_data)
                @suggestTitles(title_data)
                @populateSuggestedSearches(authors, titles)
              )

            #$('#search').on 'click', (event) =>
              #$('#info-overlay').show()
              #@populateSuggestedSearches()

  linkMagnifyClickGcf: ->
    # hack way to cause clicking #search to press enter in gcf
    console.log("linkMagnifyClickGcf executed")
    enter_press = jQuery.Event('keydown');
    enter_press.which = 13;
    $('#search').click ->
      $('#gcf').trigger(enter_press);
      $('.geosearchResults').attr('style','display: block;')


  attachNewSceneHandler: ->
    $('#new_scene_submit_btn').click( () =>
      @addPlace()
      )

  sceneFieldsTemplate: ->
    field_format = '<br><span class="pllabel"><%= label %></span>'
    field_format += '<br><span class="plcontent"><%= content %></span>'
    return _.template(field_format)

  sceneButtonTemplate: ->
    aff_span = '<span id="affbtns">'
    buybook_button =  '<span class="buybook" id="<%= buy_isbn %>">'
    buybook_button += '<img src="/img/ib.png" id="rjjbuy"/></span>'
    goodrd_button = '<span class="reviewbook" id="<%= gr_isbn %>">'
    goodrd_button += '<img id="grbtn" src="/img/goodrd.png"></span>'
    aff_span += buybook_button + goodrd_button + '</span>'
    return _.template(aff_span)

  sceneCheckinButtonTemplate: ->
    button_format = '<br><div id="checkin"><button class="btn visited"'
    button_format += 'id="<%=place_id %>">check-in</button></div>'
    return _.template(button_format)

  sceneUserImageTemplate: ->
    img = '<img class="infopic" src="<%= image_url %>">'
    return _.template(img)

  sceneAPIImageTemplate: (data_image_data) ->
    if data_image_data and data_image_data.photo_id
      console.log("data_image_data:" + JSON.stringify(data_image_data) )
      console.log("photo_id: " + data_image_data.photo_id)
    else
      console.log("data_image_data is missing")

    img = '<a target="_blank" href="//www.panoramio.com/photo/<%= image_id %>"
    class = "panoramio-image"
    style = "background-image:url(http://static2.bareka.com/photos/medium/<%= image_id %>.jpg);"></a>'

    return _.template(img)

  sceneTitleTemplate: ->
    return _.template('<span class="lead"><%= title %> by <%= author %></span>')

  buildInfowindow: (data, updateButton) ->
    console.log('buildInfowindow')
    $('#tabs').show()
    @clearInfowindowClickEvents()

    console.log "The database key is:" + data.id

    content = '<div class="plinfowindow">'
    $('#entry-image').show()

    # image not found default image
    if !data.image_data or !data.image_data.photo_id
      img = '<img src="' + window.location.origin + '/img/placingLitNoImageFound.png" />'
      $('#entry-image').html(img)

    if !!data.image_data
      $('#entry-image').html(@sceneAPIImageTemplate(data.image_data)(image_id: data.image_data.photo_id))
    $('#entry-scene-title').html(data.title + "<br />" +"<span>by "+ data.author + '</span>')
    $('#entry-place-title').html(data.title + "<br />" +"<span>by "+ data.author + '</span>')
    $('#entry-actions-title').html(data.title + "<br />" +"<span>by "+ data.author + '</span>')
    $('#entry-scene-place-name').html(data.place_name)
    $('#entry-place-place-name').html(data.place_name)
    $('#entry-place-location-name').html(data.place_name)
    $('#entry-actions-place-name').html(data.place_name)
    $('#learn-more-place-name').html(data.place_name)
    $('#entry-scene-description').html(data.description)
    $('#entry-characters-body').html(data.characters)
    $('#entry-symbols-body').html(data.symbols)
    $('#entry-place-body').html(data.notes)
    $('#entry-visits-body').html(data.visits)



    # test by Will Acheson to make Wikipedia link correct
    $('#wikiActionLink').attr('href',"https://en.wikipedia.org/w/index.php?search="+ data.place_name);
    $('#wikiActionLink2').attr('href',"https://en.wikipedia.org/w/index.php?search="+ data.place_name);

    $("#googleActionLink").attr('href', "https://www.google.com/search?q="+ data.place_name);
    $("#googleActionLink2").attr('href', "https://www.google.com/search?q="+ data.place_name);

    # getting the google search button to work on mozilla
    #https://stackoverflow.com/questions/16280684/nesting-a-inside-button-doesnt-work-in-firefox

    $("#googleActionLinkMoz").attr('href', "https://www.google.com/search?q="+ data.place_name);
    $("#googleActionLinkMoz2").attr('href', "https://www.google.com/search?q="+ data.place_name);

    $('#ibActionLink').attr('href', "http://www.rjjulia.com/book/"+ data.isbn);
    $('#grActionLink').attr('href', "https://www.goodreads.com/book/isbn/"+ data.isbn);

    $('#entry-symbols-body').html(data.symbols)
    $('#entry-place-body').html(data.notes)
    $('#entry-visits-body').html(data.visits)

    twitterlink = "https://twitter.com/intent/tweet?text=Check%20out%20"+data.title+"%20at%20"+data.place_name+"%20by%20visiting%20placing-literature.appspot.com/map/filter/id/"+data.id+"%20#getlit"
    $('#twitterActionLink').attr('href', twitterlink);
    #console.log("twitter link: " + twitterlink);
    facebooklink = 'http://www.facebook.com/share.php?u=http://www.placing-literature.appspot.com/map/filter/id/'+data.id;
    $('#facebookActionLink').attr('href', facebooklink);
    #console.log("fb link: " + facebooklink);
    $('#share_url').val('placing-literature.appspot.com/map/filter/id/'+data.id)

    if !!data.image_data
      content += @sceneAPIImageTemplate()(image_id: data.image_data.photo_id)

    content += @sceneTitleTemplate()({title: data.title, author:data.author})
    for field of @field_labels
      label = @field_labels[field]
      if data[field]
        content += @sceneFieldsTemplate()({label: label, content:data[field]})
    if updateButton
      content += @sceneCheckinButtonTemplate()(place_id: data.id)
      #@handleCheckinButtonClick()
    if !!data.isbn
      content += @sceneButtonTemplate()(gr_isbn: data.isbn, buy_isbn: data.isbn)
      @handleInfowindowButtonEvents()
    content += '</div>'

    if $('#entry-image').html == ''
      console.log('entry-image is empty, insert default image');
    return content


  openInfowindowForPlace: (place_key, windowOptions) ->
    console.log('open', windowOptions)
    $('#info-overlay').animate {
        left: '-=1000'
      },700, () ->
        $('.entry').hide()
        $('#info-overlay').show()
        $('#scene_entry').show()
        $('#tabs').show()
        $('.tab').removeClass('activeTab')
        $('#scene_tab').addClass('activeTab')
        $('#info-overlay').animate {
          left: '+=1000'
        },700
    # this can be triggered by a deep link or map marker click
    # TODO: marker clicks are tracked as events, deep links as pages- RESOLVE
    url = '/places/info/' + place_key
    console.log("openInfowindowForPlace place_key: " + place_key);
    window.PLACEKEY = null
    # console.log('open window', windowOptions)
    if windowOptions.marker
      tracking =
        'category': 'marker'
        'action': 'open window'
        'label': windowOptions.scene.get('title') + ':' + place_key
        'value' : 1
      @mapEventTracking(tracking)
    console.log("GET /places/info/" + place_key);
    $.ajax
      url: "/places/info/" + place_key,
      dataType: "json",
      success: (data) =>
        @placeInfowindow.close() if @placeInfowindow?
        iw = @infowindow()
        #console.log(windowOptions.marker.position)

        console.log('build info window success:' + this.url)

        console.log('buildInfoWindow:  data: ' + JSON.stringify(data));
        @buildInfowindow(data, true)
        console.log("openInfowindowForPlace() Location Data: " + JSON.stringify(data))
        if windowOptions.position
          #console.log(typeof windowOptions.position)
          #console.log(windowOptions.position)
          iw.setPosition(windowOptions.position)
          iw.open(@gmap)
          @gmap.setCenter(windowOptions.position)
        #else
          #iw.open(@gmap, windowOptions.marker)
        #@placeInfowindow = iw
      error: (err) =>
        console.log('build info window error:' + url)
        console.log("err: " + JSON.stringify(err));
        console.log('buildInfoWindow:  data: ' + JSON.stringify(data));


  mapEventTracking: (data)->
    ga('send', 'event', data.category, data.action, data.label, data.value)

  handleInfowindowButtonEvents: () ->
    buy_url = '//www.rjjulia.com/aff/PlacingLiterature/book/v/'
    $('#map_canvas').on 'click', '.buybook', (event) =>
      tracking =
        'category': 'button'
        'action': 'buy'
        'label': event.currentTarget.id
        'value' : 1
      @mapEventTracking(tracking)
      window.open(buy_url + event.currentTarget.id)
    $('#map_canvas').on 'click', '.reviewbook', (event) =>
      tracking =
        'category': 'button'
        'action': 'reviews'
        'label': event.currentTarget.id
        'value' : 1
      @mapEventTracking(tracking)
      window.open('//www.goodreads.com/book/isbn/' + event.currentTarget.id)

  clearInfowindowClickEvents: ->
    $('#map_canvas').off 'click', '.visited'
    $('#map_canvas').off 'click', '.buybook'
    $('#map_canvas').off 'click', '.reviewbook'

  handleCheckinButtonClick: (event) ->
    $('#map_canvas').on 'click', '.visited', (event) =>
      @isUserLoggedIn( =>
        $('.visited').hide()
        @placeInfowindow.setContent('updating...')
        $.getJSON '/places/visit/'+event.target.id, (data) =>
          @placeInfowindow.setContent(@buildInfowindow(data, false))
      )

  buildMarkerFromLocation: (location) ->
    console.log("buildMarkerFromLocation")
    #console.log("location type: " + typeof(location));
    #console.log("location: " + JSON.stringify(location));
    lat = location.get('latitude')
    lng = location.get('longitude')
    title = location.get('title')
    author = location.get('author')
    markerParams = @settings.markerDefaults
    markerParams.position = new google.maps.LatLng lat, lng
    markerParams.title = "#{ title } by #{ author }"
    marker = new google.maps.Marker(markerParams)
    @locationMarkerEventHandler(location, marker)
    return marker

  locationMarkerEventHandler: (location, marker) ->
    #console.log("location marker clicked: " + JSON.stringify(location));
    google.maps.event.addListener marker, 'click', (event) =>
      windowOptions =
        marker: marker
        scene: location

      placeInfo = location.get('db_key');
      console.log("locMarkEventHandl: placeInfo: " + JSON.stringify(placeInfo));
      @openInfowindowForPlace(location.get('db_key'), windowOptions)


  dropMarkerForStoredLocation: (location) ->
    console.log("dropMarkerForStoredLocation")
    marker = @buildMarkerFromLocation(location)
    marker.setMap(@gmap)

  handleInputAttributes: ->
    fields = $('#iwcontainer input')
    dealWithIE9Inputs = (el) ->
      el.setAttribute('value', el.getAttribute('placeholder'))
    dealWithIE9Inputs(field) for field in fields


class PlacingLit.Views.RecentPlaces extends Backbone.View
  model: PlacingLit.Models.Location
  el: '#recentcontent'
  max_desc_length: 100

  initialize: () ->
    @collection = new PlacingLit.Collections.Locations
    @collection.fetch(url: '/places/recent')
    @listenTo @collection, 'all', @render

  render: (event) ->
    @showNewestPlaces() if event is 'sync'

  showNewestPlaces: () ->
    locations = @collection.models
    listFragment = document.createDocumentFragment()
    @$el.find('li').remove()
    listItems = (@getPlaceLink(location) for location in locations)
    listFragment.appendChild(link) for link in listItems
    @$el.append(listFragment)
    return listFragment

  getPlaceLink: (place) ->
    li = document.createElement('li')
    li.className = 'searchResultText'
    li.id = place.get('db_key')
    link = document.createElement('a')
    link.href = '/map/' + place.get('latitude') + ',' + place.get('longitude')
    link.href += '?key=' + place.get('db_key')
    title = place.get('title')
    link.textContent = title
    if place.get('location')?
      location = place.get('location')
      if (location + title).length > @max_desc_length
        location = location.substr(0, @max_desc_length - title.length) + '...'
      link.textContent += ': ' + location
    li.appendChild(link)
    return li


class PlacingLit.Views.Countview extends Backbone.View
  el: '#count'

  initialize: () ->
    @model = new PlacingLit.Models.Metadata
    @model.fetch(url: '/places/count')
    @listenTo @model, 'all', @render

  render: (event) ->
    @showCount() if event is 'change:count'

  showCount: () ->
    $(@el).text(@model.get('count') + ' scenes have been mapped')


class PlacingLit.Views.Allscenes extends Backbone.View
  el: '#scenelist'

  initialize: () ->
    @collection = new PlacingLit.Collections.NewestLocationsByDate
    @collection.fetch()
    @listenTo @collection, 'all', @render

  render: (event) ->
    @showAllScenes() if event is 'sync'

  showAllScenes: () ->
    locations = @collection.models
    listFragment = document.createDocumentFragment()
    listItems = (@getPlaceLink(location) for location in locations)
    listFragment.appendChild(link) for link in listItems
    @$el.append(listFragment)
    return listFragment

  getPlaceLink: (place) ->
    li = document.createElement('li')
    li.id = place.get('db_key')
    # li.addEventListener('click', (event) =>
    #   @getPlaceDetails(event)
    # )
    link = document.createElement('a')
    link.href = '/map/' + place.get('latitude') + ',' + place.get('longitude')
    link.href += '?key=' + place.get('db_key')
    link.textContent = place.get('title') + ': ' + place.get('location')
    editLink = document.createElement('a')
    editLink.href = '/admin/edit?key=' + place.get('db_key')
    editImage = document.createElement('img')
    editImage.src = '/img/edit-icon.png'
    editImage.style.height = '16px'
    editImage.className = 'editicon'
    editLink.appendChild(editImage)
    li.appendChild(editLink)
    li.appendChild(link)
    return li


class PlacingLit.Views.MapFilterView extends PlacingLit.Views.MapCanvasView
  #TODO - FIX THIS MONSTROSITY!!!
  filteredViewGeocoderSearch: () ->
    console.log("filteredViewGeocoderSearch ")
    address = document.getElementById('gcf').value
    # console.log('address')
    if address
      geocoder = new google.maps.Geocoder()
      geocoder.geocode {'address':address}, (results, status) =>
        if (status == google.maps.GeocoderStatus.OK)
          position = results[0].geometry.location
          lat = position[Object.keys(position)[0]]
          lng = position[Object.keys(position)[1]]
          mapUrl = window.location.protocol + '//' + window.location.host
          mapUrl += '/map/' + lat + ',' + lng
          # mapUrl += '/map?lat=' + lat + '&lon=' + lng
          window.location = mapUrl
        else
          alert("geocode was not successful: " + status)

  attachFilteredViewSearchHandler: ->
    document.getElementById("mapOverlay").style.display = 'none'
    $('#gcf').on('keydown',
      (event) =>
        if (event.which == 13 || event.keyCode == 13)
          event.preventDefault()
          @filteredViewGeocoderSearch()
      )
    $('#search').on 'click', (event) =>
      @filteredViewGeocoderSearch()

  linkMagnifyClickGcf: ->
    # hack way to cause clicking #search to press enter in gcf
    enter_press = jQuery.Event('keydown');
    enter_press.which = 13;
    $('#search').click ->
      $('#gcf').trigger(enter_press);


  initialize: (scenes) ->
    console.log("map filter view:  scenes ")
    console.log("scenes: " + JSON.stringify(scenes) )
    console.log(scenes)

    @getRecentBlog();

    # console.log('filtered view', scenes)
    @collection ?= new PlacingLit.Collections.Locations()
    @listenTo @collection, 'all', @render
    @collection.reset(scenes)
    @authors = @suggestAuthors()

    # is a map/filter/id share link style link
    pathname = window.location.pathname;
    if (pathname.indexOf("map") > -1 and pathname.indexOf("filter") > -1 and pathname.indexOf("id") > -1)
      # opens the scene card for this place share link by default
      @openInfoWindowForShareLink(scenes);

  openInfoWindowForShareLink: (scene) =>
    #console.log("openInfoWindowForShareLink: " + JSON.stringify(scene[0]));
    db_key = scene[0].db_key;

    $('#info-overlay').animate {
        left: '-=1000'
      },700, () ->
        $('.entry').hide()
        $('#info-overlay').show()
        $('#scene_entry').show()
        $('#tabs').show()
        $('.tab').removeClass('activeTab')
        $('#scene_tab').addClass('activeTab')
        $('#info-overlay').animate {
          left: '+=1000'
        },700

    url = '/places/info/' + db_key
    #console.log("openInfowindowForShareLinl");
    #window.PLACEKEY = null
    #console.log("GET /places/info/" + db_key);
    $.ajax
      url: "/places/info/" + db_key,
      dataType: "json",
      success: (data) =>
        @placeInfowindow.close() if @placeInfowindow?
        iw = @infowindow()
        #console.log('build info window success:' + this.url)
        #console.log('buildInfoWindow:  data: ' + JSON.stringify(data));
        @buildInfowindow(data, true)
        console.log("openInfowindowForPlace() Location Data: " + JSON.stringify(data))
        iw.open(@gmap, windowOptions.marker)
        @placeInfowindow = iw
      error: (err) =>
        console.log('build info window error:' + url)
        console.log("err: " + JSON.stringify(err));
        #console.log('buildInfoWindow:  data: ' + JSON.stringify(data));

  render: (event) ->
    @gmap ?= @googlemap()
    @allMarkers = @markerArrayFromCollection(@collection)
    @markerClustersForScenes(@allMarkers)
    @markersForEachScene(@collection)
    @attachSearchHandler()
    @linkMagnifyClickGcf() # make clicking magnifying glass icon press enter in search box
    mapcenter = new google.maps.LatLng(window.CENTER.lat, window.CENTER.lng)
    @gmap.setCenter(mapcenter)

    # if this is a collection map, set the zoom level to wide
    if (window.location.pathname.indexOf("collections") != -1)
      @gmap.setZoom(@settings.zoomLevel.wide)
    else
      @gmap.setZoom(@settings.zoomLevel.close)

    $('#addscenebutton').on('click', @handleAddSceneButtonClick)
    $('#addscenebutton').show()

  updateCollection: (event) ->
    center = @gmap.getCenter()
    centerGeoPt =
      lat: center[Object.keys(center)[0]]
      lng: center[Object.keys(center)[1]]
    zoom = @gmap.getZoom()
    console.log('pan/zoom idle', centerGeoPt, zoom, @collection.length)
    if window.CENTER?
      console.log(window.CENTER)
      console.log(Math.abs(window.CENTER.lat - centerGeoPt.lat))
      console.log(Math.abs(window.CENTER.lng - centerGeoPt.lng))
    else
      window.CENTER = centerGeoPt

    update = false
    if Math.abs(window.CENTER.lat - centerGeoPt.lat) > 5
      update = true
    if Math.abs(window.CENTER.lng - centerGeoPt.lng) > 5
      update = true

    if update
      console.log('adding new scenes')
      query = '?lat=' + centerGeoPt.lat + '&lon=' + centerGeoPt.lng
      collection_url = '/places/near' + query
      new_markers = new PlacingLit.Collections.Locations
      new_markers.url = collection_url
      current_collection = @collection
      window.CENTER = centerGeoPt
      new_markers.fetch(
        success: (collection, response, options) =>
          console.log('current', current_collection.length,
                       current_collection.models)
          console.log('new', collection.length, collection.models)
          union = _.union(current_collection.models, collection.models)
          set_options =
            add: true
            remove: false
            merge: false
          @collection.reset(union, set_options)
          # @allMarkers = @markerArrayFromCollection(@collection)
          # @markersForEachScene(@allMarkers)
          # updated_collection = _.union(current_collection, collection)
          # console.log('updated', updated_collection.length)
          # @allMarkers = @markerArrayFromCollection(updated_collection)
          # @markersForEachScene(@collection)
          # @markerClustersForScenes(@allMarkers)
        error: (collection, response, options) =>
          console.log('error', collection, response, options)
        )
