""" home page request handlers """
# pylint
import sys
import os.path


import re
from HTMLParser import HTMLParser
import location_index


import json
import logging
import random

from google.appengine.ext import webapp
from google.appengine.ext import db
from google.appengine.ext import deferred

from classes import placedlit

from handlers.abstracts import baseapp

import blogposts


class HomeHandler(baseapp.BaseAppHandler):
  def get(self):
    template_values = self.basic_template_content()
    template_values['title'] = 'Home'
    posts = blogposts.BlogpostsHandler.posts_for_display()
    bloglinks = [{'title': post.title, 'link': post.link} for post in posts]
    template_values['posts'] = bloglinks

    template_values['remote_addr'] = self.request.remote_addr
    self.render_template('home.tmpl', template_values)


class AboutHandler(baseapp.BaseAppHandler):
  def get(self):
    template_values = self.basic_template_content()
    template_values['title'] = 'About'
    self.render_template('about_page.tmpl', template_values)

  """def post(self):
    sender = self.request.get('name')
    subject = 'Placing Lit Contact Form'
    text = self.request.get('message')
    server = smtplib.SMTP("Server")
    server.sendmail(sender, "laurenbeecher@gmail.com", text)
    server.quit()
    template_values = self.basic_template_content()
    template_values['title'] = 'About'
    self.render_template('about_page.tmpl', template_values)"""


class FundingHandler(baseapp.BaseAppHandler):
  def get(self):
    template_values = self.basic_template_content()
    template_values['title'] = 'Funding'
    self.render_template('funding.tmpl', template_values)

# Handler for loading the map
class MapHandler(baseapp.BaseAppHandler):
  def get(self, location=None, key=None):
      template_values = self.basic_template_content()
      template_values['title'] = 'Map'
      template_values['count'] = placedlit.PlacedLit.count()
      if location and ',' in location:
        (lat, lng) = location.replace('/', '').split(',')
        template_values['center'] = '{lat:%s,lng:%s}' % (lat, lng)
      if self.request.get('key'):
        template_values['key'] = self.request.get('key')

      #  gives map.tmpl the data stored in template_values
      # for rendering on the desktop site
      self.render_template('map.tmpl', template_values)

class IndexedSceneMapHandler(baseapp.BaseAppHandler):
  def get(self, location=None, key=None):
    template_values = self.basic_template_content()
    template_values['title'] = 'Map'
    key = self.request.get('key')
    lat = self.request.get('lat')
    # FIXIT- Pick one: 'lon', 'lng'
    if self.request.get('lon'):
      lng = self.request.get('lon')
    else:
      lng = self.request.get('lng')
    if lat and lng:  # lat, lng with no scene
      logging.info('got lat, lng in query string')
      template_values['center'] = '{lat:%s,lng:%s}' % (lat, lng)
      template_values['scenes'] = self.get_nearby_places_json(lat=lat, lng=lng)
    elif key:  # scene but no lat, lng
      logging.info('got key')
      template_values['key'] = key
      scene_doc = placedlit.get_search_doc_for_scene(key)
      if scene_doc:
        scene = self.format_location_index_doc(scene_doc)
        lat = scene['latitude']
        lng = scene['longitude']
        template_values['center'] = '{lat:%s,lng:%s}' % (lat, lng)
        template_values['scenes'] = self.get_nearby_places_json(lat=lat,
                                                                lng=lng)
      else:
        logging.debug('no doc in location index for %s', key)
    elif location and ',' in location:
      logging.info('got location in path')
      (lat, lng) = location.replace('/', '').split(',')
      template_values['center'] = '{lat:%s,lng:%s}' % (lat, lng)
      template_values['key'] = key
    self.render_template('map.tmpl', template_values)

  # TODO: figure out if this works, read the code from it
  def get_nearby_places_json(self, lat=None, lng=None):
    # TODO sorted is broken, will fix (mayb)
    #places = placedlit.get_nearby_places(lat, lng, sorted=True)
    places = placedlit.get_nearby_places(lat, lng)
    if places:
      return json.dumps(self.format_location_index_results(places))
    else:
     return None


class UserstatusHandler(baseapp.BaseAppHandler):
  def get(self):
    return self.get_user_status()


class AllscenesHandler(baseapp.BaseAppHandler):
  def get(self):
    template_values = self.basic_template_content()
    template_values['title'] = 'All Scenes'
    self.render_template('all.tmpl', template_values)


class AdminEditSceneHandler(baseapp.BaseAppHandler):
  def get(self):
    template_values = self.basic_template_content()
    template_values['title'] = 'Edit Scene'
    place_id = self.request.get('key')
    place = placedlit.PlacedLit.get_place_from_id(place_id)
    template_values['place'] = place
    self.render_template('edit.tmpl', template_values)

  def post(self):
    """ add scene from user submission """
    place = placedlit.PlacedLit.get_place_from_id(self.request.get('key'))
    if place:
      place_data = dict()
      update_fields = ['title', 'author', 'scenelocation', 'scenedescription',
                       'notes', 'image_url', 'actors', 'scenetime', 'symbols',
                       'ug_isbn']
      for field in update_fields:
        place_data[field] = self.request.get(field)
      place.update_fields(place_data)
      self.response.out.write('Saved')

  def delete(self):
    logging.info('deleted %s', self.request.get('key'))
    place = placedlit.PlacedLit.get_place_from_id(self.request.get('key'))
    place.delete_scene()
    self.response.out.write('Deleted')


class NewhomeHandler(baseapp.BaseAppHandler):
  def get(self):
    template_values = self.basic_template_content()
    template_values['title'] = 'Home'
    posts = blogposts.BlogpostsHandler.posts_for_display()
    bloglinks = [{'title': post.title, 'link': post.link} for post in posts]
    template_values['posts'] = bloglinks
    self.render_template('placinglit.tmpl', template_values)


class MapFilterHandler(baseapp.BaseAppHandler):
  def get(self, field=None, term=None):
    template_values = self.basic_template_content()
    template_values['title'] = 'Map'
    template_values['count'] = placedlit.PlacedLit.count()
    places = placedlit.PlacedLit.places_by_query(field, term)
    loc_json = []
    if places:
      if field == 'author' or field == 'title':
        loc_json = self.format_location_index_results(places)
      else:
        loc_json = [self.export_place_fields(place) for place in places]
    if loc_json:
      some_scene = random.choice(loc_json)
      template_values['center'] = '{{lat:{}, lng:{}}}'.format(
        some_scene['latitude'], some_scene['longitude'])
    template_values['scenes'] = json.dumps(loc_json)
    template_values['log'] = json.dumps(loc_json)
    self.render_template('map.tmpl', template_values)

# because placedlit.PlacedLit is used in getting "places" in
# the above method, I think it will be safe to create a new
# handler that will return nearby places by lng, lat
# and render a map.

class MapFilterCoordsHandler(baseapp.BaseAppHandler):
  def get(self, query=None ):
    template_values = self.basic_template_content()
    template_values['title'] = 'Map'

    #template_values['count'] = placedlit.PlacedLit.count()
    '''
    print "query: " + Query

    lat = self.request.get('lat')
    lon = self.request.get('lon')

    print lat
    print lon


    places = location_index.sorted_location_query(lat, lon)
    formatted_results = self.format_location_index_results(places)

    template_values['scenes'] = json.dumps(formatted_results)'''

    template_values['scenes'] = "1234"
    self.render_template('map.tmpl', template_values)

    '''
    #lat = self.request.GET['lat']
    #lon = self.request.GET['lon']

    logging.info("lat ", lat)
    logging.info("lon ", lon)

    places_near = placedlit.get_nearby_places(lat, lon, False)
    template_values['scenes'] = json.dumps(places_near)

    location = location.split('&')
    for loc in location:
        print "loc: " + loc

    lat = location[0]
    lng = location[1]

    if lat and lon:
      places_near = placedlit.get_nearby_places(lat, lon, False)
      template_values['scenes'] = json.dumps(places_near)
     loc_json = []
    #if places_near:
    loc_json = self.format_location_index_results(places_near)
    if loc_json:
      some_scene = random.choice(loc_json)
      template_values['center'] = '{{lat:{}, lng:{}}}'.format(
        some_scene['latitude'], some_scene['longitude'])
      template_values['scenes'] = json.dumps(loc_json)
        # test purposes
    logging.info('mapFilterCoords template_values' + type(template_values))
    self.render_template('map.tmpl', template_values)'''





class AdminMenuHandler(baseapp.BaseAppHandler):
  def get(self):
    template_values = self.basic_template_content()
    template_values['title'] = 'Admin Menu'
    self.render_template('admin.tmpl', template_values)

class AuthorSpotlightHandler(baseapp.BaseAppHandler):
  def get(self):
    template_values = self.basic_template_content()
    template_values['title'] = 'Author Spotlight'
    self.render_template('author-spotlight.tmpl', template_values)

class CollectionsHandler(baseapp.BaseAppHandler):
  def get(self):
    template_values = self.basic_template_content()
    template_values['title'] = 'Collections'
    self.render_template('collections.tmpl', template_values)

class CloseByHandler(webapp.RequestHandler):
  def get(self):

    client_lat = self.request.GET.get('lat', '')
    client_lng = self.request.GET.get('lng', '')

    if client_lng and client_lat:
      # Search for scenes near client_location

      location = dict(
        lat = client_lat,
        lng = client_lng
      )

      nearby_places = self.run_proximity_query(location['lat'], location['lng'])

      nearby_places_json = json.dumps(nearby_places)
      location_json = json.dumps(location)

      self.response.headers['Content-Type'] = 'application/json; charset=utf-8'

      self.response.write(nearby_places_json)
      print " "
      print "Client Location -  lat: " + client_lat + " long " + client_lng


  def run_proximity_query(self, lat, long, distance = 80450 ):
    local_scenes = location_index.\
      location_index.\
      sorted_location_query(lat, long, 80450) # 50 mile distance for now

    print "results of proximity query: " + str(local_scenes)
    for scene in local_scenes:
      print scene + '\n'



    return local_scenes


urls = [
  ('/about', AboutHandler),
  ('/all', AllscenesHandler),
  ('/authorspotlight', AuthorSpotlightHandler),
  ('/funding', FundingHandler),
  ('/home', HomeHandler),
  ('/map/filter/(.*)/(.*)', MapFilterHandler),
  #('/map/coords/(\-?\d*\.\d*\&\-?\d*\.\d*)', MapFilterCoordsHandler),
  ('/map/coords/(/?.*)', MapFilterCoordsHandler),
  ('/map(/?.*)', MapHandler),
  ('/', MapHandler),
  ('/user/status', UserstatusHandler),
  ('/desktop/', NewhomeHandler),
  ('/admin/edit', AdminEditSceneHandler),
  ('/admin/menu', AdminMenuHandler),
  ('/oldhome', HomeHandler),
  ('/collections', CollectionsHandler),
  ('/mobile/closeby', CloseByHandler)
]

app = webapp.WSGIApplication(urls, debug=True)
