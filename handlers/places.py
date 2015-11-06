""" Request handlers for places. """
# pylint: disable=W0403, R0904, C0103


import datetime
import logging

from string import capwords
from datetime import datetime

from google.appengine.ext import webapp
from google.appengine.api import users
from google.appengine.api import memcache
from google.appengine.api import search


from handlers.abstracts import baseapp
from classes import placedlit


def is_image_url(url):
  """ supported image url? """
  return url.rsplit('.')[-1] in ['jpg', 'png', 'gif']


class GetPlacesHandler(baseapp.BaseAppHandler):
  """ get all places and return as list of json objects"""
  def get(self):
    places = placedlit.PlacedLit.get_all_places()
    loc_json = []
    for place in places:
      place_dict = {
        'latitude': place.location.lat,
        'longitude': place.location.lon,
        'db_key': place.key().id(),
        'title': place.title,
        'author': place.author
      }
      loc_json.append(place_dict)
    # loc_json = [self.export_place_fields(place) for place in places]
    self.output_json(loc_json)

class GetPlacesNearHandler(baseapp.BaseAppHandler):
    ''' get 300 nearby places, called every time the map loads or changes view'''
    def get(self, location):
        print ("GetPlacesNearHandler !!!!!!!!!!!!!!!!!!")
        location = location.split('&')
        for loc in location:
            print "loc: " + loc

        lat = location[0]
        lng = location[1]

        #print ("This is the client location: " + location)

        ''' verify we have the client's location '''
        if (lat and lng):
            places_near = placedlit.get_nearby_places(lat, lng, False)
            loc_json = []
            for place in places_near:
                place_dict = {
                  'latitude': place.location.lat,
                  'longitude': place.location.lon,
                  'db_key': place.key().id(),
                  'title': place.title,
                  'author': place.author
                }
                loc_json.append(place_dict)
            #self.output_json(loc_json)
            self.response.out.write(places_near)
        else:
            self.response.out.write("error: location data error")


class GetPlacesByTitleHandler(baseapp.BaseAppHandler):
  """Get places by title"""
  def get(self, title):
    places = placedlit.PlacedLit.get_all_places()
    loc_json = []
    for place in places:
      if place.title and title in place.title:
        place_dict = {
          'latitude': place.location.lat,
          'longitude': place.location.lon,
          'db_key': place.key().id(),
          'title': place.title,
          'author': place.author
        }
        loc_json.append(place_dict)
    self.output_json(loc_json)

class GetPlacesByDateHandler(baseapp.BaseAppHandler):
  """ get all places sorted by date return as list of json objects"""
  def get(self):
    count = placedlit.PlacedLit.count()
    places = placedlit.PlacedLit.get_newest_places(limit=count)
    stats = memcache.get_stats()
    logging.info('memcache stats: %s' % (stats))
    loc_json = [self.export_place_fields(place) for place in places]
    self.output_json(loc_json)


class RecentPlacesHandler(baseapp.BaseAppHandler):
  """ get newest 10 places sorted by date return as list of json objects"""
  def get(self):
    places = placedlit.PlacedLit.get_newest_places(limit=10)
    loc_json = []
    for place in places:
      date_added = place.ts.strftime('%m-%d-%Y')
      geo_pt = place.location
      key = place.key()
      loc = {
        'latitude': geo_pt.lat,
        'longitude': geo_pt.lon,
        'title': place.title,
        'author': place.author,
        'date_added': date_added,
        'db_key': key.id()}
      if place.scenelocation:
        loc['location'] = capwords(place.scenelocation)
      loc_json.append(loc)
    self.output_json(loc_json)


class InfoHandler(baseapp.BaseAppHandler):
  """ get info about a scene by id. """
  def get(self, place_id):
    place = placedlit.PlacedLit.get_place_from_id(place_id)
    if place:
      date_added = place.ts.strftime('%m-%d-%Y')
      place_info = {
        'id': place_id,
        'title': place.title,
        'author': place.author,
        'place_name': place.scenelocation,
        'scenetime': place.scenetime,
        'actors': place.actors,
        'symbols': place.symbols,
        'description': place.scenedescription,
        'notes': place.notes,
        'date_added': date_added,
        'visits': place.checkins,
      }
      if place.ug_isbn:
        place_info['isbn'] = place.ug_isbn
      elif place.book_data:
        place_info['isbn'] = place.book_data.isbn13
      if place.get_image_data():
        place_info['image_data'] = place.get_image_data()
      elif place.image_url:
        if is_image_url(place.image_url):
          place_info['image_url'] = place.image_url.replace('http://', '//')
      self.output_json(place_info)


class ExportPlacesHandler(baseapp.BaseAppHandler):
  """ get places for csv export """
  def get(self):
    places = placedlit.PlacedLit.get_all_places()
    row_id = 1
    loc_csv = '"id","title","author","latitude","longitude","email"\n'
    fields = '"{}","{}","{}","{}","{}","{}"\n'
    for place in places:
      geo_pt = place.location
      try:
        loc_csv += fields.format(
          row_id, place.title, place.author,
          geo_pt.lat, geo_pt.lon, place.user_email)
        row_id += 1
      except UnicodeEncodeError:
        pass
    filename = 'filename="placingliterature_export_'
    filename += datetime.date.today().isoformat() + '.csv"'
    self.response.headers['Content-Type'] = 'text/csv'
    self.response.headers['Content-Disposition'] = 'attachment; ' + filename
    self.response.out.write(loc_csv)


class PlacesVisitHandler(baseapp.BaseAppHandler):
  """ update visit count for a place. """
  def get(self, place_id):
    user_email = users.get_current_user().email()
    place = placedlit.PlacedLit.get_place_from_id(place_id)
    place.update_visit_count(user_email)
    info_path = '/places/info/' + place_id
    self.redirect(info_path)


class CountPlacesHandler(baseapp.BaseAppHandler):
  """ get a count of places added."""
  def get(self):
    count_data = {
      'count': placedlit.PlacedLit.count()
    }
    self.output_json(count_data)


class PlacesAuthors(baseapp.BaseAppHandler):
  """ get authors."""
  def get(self):
    authors = placedlit.PlacedLit.get_all_authors()
    self.output_json(authors)


class PlacesTitles(baseapp.BaseAppHandler):
  """ get titles. """
  def get(self):
    titles = placedlit.PlacedLit.get_all_titles()
    # title_json = []
    # for places in title_places:
    #   title_json.append({'title': places.title.replace('\"', '')})
    self.output_json(titles)

class GetAuthorByNameHandler(baseapp.BaseAppHandler):
  """ get an author by name"""
  def get(self, name):
    data = placedlit.PlacedLit.places_by_query('author',name)
    respArray = []
    for res in data.results:
      resp = {}
      for field in res.fields:
        if str(type(field.value)) == "<class 'google.appengine.api.search.search.GeoPoint'>":
          entry = {
            'latitude': field.value.latitude,
            'longitude': field.value.longitude
          }
          resp[field.name] = entry
        else:
          resp[field.name] = str(field.value)
        respArray.append(resp)
    self.output_json(respArray)

urls = [
  ('/places/show', GetPlacesHandler),
  ('/places/near/(\-?\d*\.\d*\&\-?\d*\.\d*)', GetPlacesNearHandler),
  ('/places/info/(.*)', InfoHandler),
  ('/places/visit/(.*)', PlacesVisitHandler),
  ('/places/recent', RecentPlacesHandler),
  ('/places/export', ExportPlacesHandler),
  ('/places/count', CountPlacesHandler),
  ('/places/authors', PlacesAuthors),
  ('/places/titles', PlacesTitles),
  ('/places/allbydate', GetPlacesByDateHandler),
  ('/places/authors/(.*)', GetAuthorByNameHandler),
  ('/places/titles/(.*)', GetPlacesByTitleHandler),
]

app = webapp.WSGIApplication(urls, debug=True)
