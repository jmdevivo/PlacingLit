class PLMap

  constructor: ->
    @elements =
      modals:
        mapmodal: $('#mapmodal')
        querymodal: $('#querymodal')
    @path = window.location.pathname # intially = '/'

    @search = @parseQuery(window.location.search)
    #console.log('placelit.coffee :: search object: ' + JSON.stringify(@search))
    @scenes = window.SCENES

    #console.log('placelit.coffee :: scenes: ' + @scenes)

  showModal: (element) ->
    element.modal()

  isFiltered: ->
    #if (@path.indexOf('collections') == -1) and (@path.indexOf('author') == -1) and (@path.indexOf('title') == -1) and (@path.indexOf('coordinates') == -1)
    if (@path.indexOf('collections') == -1) and (@path.indexOf('author') == -1) and (@path.indexOf('title') == -1) and (@path.indexOf('coords') == -1) and (@path.indexOf('filter') == -1)
      console.log('isFiltered false');
      return false
    console.log('isFiltered true');
    return true

  hasScenes: ->
    return @scenes and @scenes.length > 0

  selectMapView: ->
    if @isFiltered() and @hasScenes()
      console.log("this is a search =================")
      # This means the view is the result of a search
      return new PlacingLit.Views.MapFilterView(@scenes)
    console.log("this is a default view ===============")
    # This means the view is a default map view
    return new PlacingLit.Views.MapCanvasView

  isShareLink: ->
    pathname = window.location.pathname;
    if (pathname.indexOf("map") > -1 and pathname.indexOf("filter") > -1 and pathname.indexOf("id") > -1)
      console.log("is share link");
      return true;

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
    console.log('parseQuery result: ' + JSON.stringify(result));

  parseURI: (URI) ->
    split = URI.split '/'
    return split

$ ->
  plmap = new PLMap()
  view = plmap.selectMapView()
  '''
  if plmap.isShareLink() == true
    uri = plmap.parseURI(window.location.pathname)
    #view.openInfowindowForPlace(uri[4], )
  '''
  console.log('view created: ' + view.constructor.name )
  if location.search is '?modal=1'
    plmap.showModal(plmap.elements.modals.mapmodal)
  else if plmap.isFiltered()

    if plmap.scenes and plmap.scenes.length > 0
      plmap.closeFeatContent()
      plmap.showModal(plmap.elements.modals.querymodal)
    else
      plmap.displayEmptyResultsError()
      if history
        console.log "history should be cleared"
        history.replaceState(null,null,'/')

  view.handleInputAttributes() if not Modernizr.input.placeholder
  view.showInfowindowFormAtLocation()
  # testing /blog/latest URI



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

'''
$.ajax
  url: "/places/recent",
  dataType: "json",
  success: (data) =>
    #console.log("/places/recent: " + JSON.stringify(data[0]))
    $('#newest_scene').html("<b>" + data[0]['location'] + "</b> from <i> " + data[0]['title'] + "</i> by " + data[0]['author'])
  error: (err) =>
    console.log("error: /places/recent - " + err )
'''

$.ajax
  url: "/places/info/6547073193213952",
  dataType: "json",
  success: (data)=>
    console.log("places/info test: ")
    console.log(JSON.stringify(data));
  error: (err) =>
    console.log("error: /places/info - " + JSON.stringify(err) )

'''
$.ajax
  url:"/collections/slq",
  success: (data) =>
    console.log("slq collection: ");
    console.log(data);
  error: (err) =>
    console.log("error: /collections/slq - " + JSON.stringify(err) )

'''
