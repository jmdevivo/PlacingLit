'''class MobilePLMap
  constructor: ->
    #startPos = null
    @elements =
      ###modals:
        mapmodal: $('#mapmodal')
        querymodal: $('#querymodal')###
    @path = window.location.pathname # intially = '/'

    @search = @parseQuery(window.location.search)
    @scenes = window.SCENES

    console.log('MobilePLMap initalized')


  showModal: (element) ->
    element.modal()

  isFiltered: ->
    if (@path.indexOf('collections') == -1) and (@path.indexOf('author') == -1) and (@path.indexOf('title') == -1)
      return false
    return true

  hasScenes: ->
    return @scenes and @scenes.length > 0

  closeFeatContent: ->
    $('#mapOverlay').hide()

  parseQuery: (q)->
    result = {}
    splitq = q.split '&'
    for param in splitq
      vals = param.split '='
      result[vals[0]] = vals[1]
    result

  selectMapView: ->
    # Temporary hack to get a map down on the page

    if @isFiltered() and @hasScenes()
      # This means the view is the result of a search
      return new PlacingLit.Views.MapFilterView(@scenes)
      # This means the view is a default map view

    return new PlacingLit.Views.MapCanvasView


$ ->
  plmap = new MobilePLMap()
  view = new plmap.selectMapView()
  console.log("new moblie plmap view created " + view.constructor.name)
  #plmap.showModal(plmap.elements.modals.mapmodal)
  view.setUserPlaceFromLocation()
  '''

class PLMap

  constructor: ->
    @elements =
      modals:
        mapmodal: $('#mapmodal')
        querymodal: $('#querymodal')
    @path = window.location.pathname # intially = '/'

    @search = @parseQuery(window.location.search)
    console.log('placelit.coffee :: search object: ' + JSON.stringify(@search))
    @scenes = window.SCENES
    console.log('placelit.coffee :: scenes: ' + @scenes)

  showModal: (element) ->
    element.modal()

  isFiltered: ->
    if (@path.indexOf('collections') == -1) and (@path.indexOf('author') == -1) and (@path.indexOf('title') == -1)
      return false
    return true

  hasScenes: ->
    return @scenes and @scenes.length > 0

  selectMapView: ->
    if @isFiltered() and @hasScenes()
      # This means the view is the result of a search
      return new PlacingLit.Views.MapFilterView(@scenes)
      # This means the view is a default map view
    return new PlacingLit.Views.MapCanvasView

  closeFeatContent: ->
    $('#mapOverlay').hide()

  displayEmptyResultsError: ->
    author_path = '/map/filter/author/'
    author = decodeURIComponent(@path.replace(author_path,''))
    alertMessage = 'Whoa! No places found for ' + author + '. '
    alertMessage += 'But that\'s ok!. Be the first to map this author. '
    alertMessage += 'Click the map to add a book and author.'
    alert alertMessage

  parseQuery: (q)->
    result = {}
    splitq = q.split '&'
    for param in splitq
      vals = param.split '='
      result[vals[0]] = vals[1]
    result


$ ->
  plmap = new PLMap()
  view = plmap.selectMapView()
  console.log('placelit.coffee :: view created: ' + view.constructor.name )
  if location.search is '?modal=1'
    plmap.showModal(plmap.elements.modals.mapmodal)
  else if plmap.isFiltered()
    if plmap.scenes and plmap.scenes.length > 0
      plmap.closeFeatContent()
      #plmap.showModal(plmap.elements.modals.querymodal)
    else
      plmap.displayEmptyResultsError()
      if history
        console.log "history should be cleared"
        history.replaceState(null,null,'/')
  #view.handleInputAttributes() if not Modernizr.input.placeholder
  #view.showInfowindowFormAtLocation()
  # this is going to test the client -> server -> client comm pattern
  console.log("hi")
  view.reportUserLocationToServer()
