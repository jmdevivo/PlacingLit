""" home page request handlers """
# pylint
import sys
import os.path

sys.path.append(os.path.join(os.path.dirname(__file__), '../static/python_modules/feedparser'))

import feedparser
import re
from HTMLParser import HTMLParser


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
    if "Mobi" in self.request.headers.get('User-Agent'):
      template_values = self.basic_template_content()
      template_values['title'] = 'Map'
      self.render_template('mobile-map.tmpl', template_values)
    else:
      template_values = self.basic_template_content()
      template_values['title'] = 'Map'
      template_values['count'] = placedlit.PlacedLit.count()
      if location and ',' in location:
        (lat, lng) = location.replace('/', '').split(',')
        template_values['center'] = '{lat:%s,lng:%s}' % (lat, lng)
      if self.request.get('key'):
        template_values['key'] = self.request.get('key')



      '''blog_getter = BlogHandler()
      recent_blog = blog_getter.getRecentBlogPost()
      print "decoupled recent blog data =========================="
      print recent_blog'''


      # TODO Make this not digusting.  Put blog loading in its own handler function
      # TODO Dynamic Blog Loading via XML
      # NOTE: The structure of the RSS feed is different when requesting from Python
      #   than what it looks like on a browser...
      placing_lit_blog_rss = 'http://placingliterature.wordpress.com/feed/'
      blog_feed = feedparser.parse(placing_lit_blog_rss)
      #.strftime('%b %d, %Y ')

      recent_blog_title =  blog_feed.entries[0].title
      recent_blog_summary = blog_feed.entries[0].summary
      recent_blog_link = blog_feed.entries[0].links[0].href
      recent_blog_published = blog_feed.entries[0].published
      recent_blog_author = blog_feed.entries[0].author

      # Hacky regex method of formating the date,  will grab everything up until the
      # 4 digit YEAR (2015)
      pubdate_regex = re.compile('.* [0-9]{4}')
      pubdate_re_match = pubdate_regex.match(recent_blog_published)
      if (pubdate_re_match):
        recent_blog_published = pubdate_re_match.group(0)

      # Pretty good method of HTML stripping

      recent_blog_summary = self.strip_tags(recent_blog_summary)
      recent_blog_summary = recent_blog_summary[:-3]
      recent_blog_summary = recent_blog_summary + "..."

      print "\nRecent Blog Post!"
      print "Title: " + recent_blog_title + "\n =============================="
      print "Summary: " + recent_blog_summary + "\n =============================="
      print "Link: " + str(recent_blog_link) + "\n =============================="
      print "\n"

      # load up template with blog values for display in the featured content pane
      template_values['recent_blog_title'] = recent_blog_title
      # TODO format blog content to remove code
      template_values['recent_blog_summary'] = recent_blog_summary
      template_values['recent_blog_link'] = recent_blog_link

      template_values['recent_blog_published'] = recent_blog_published
      template_values['recent_blog_author'] = recent_blog_author

      recent_scene = self.get_most_recent_scene()
      try:
        template_values['most_recent_scene_author'] = recent_scene['author']
        template_values['most_recent_scene_title'] = recent_scene['title']
        template_values['most_recent_scene_scenelocation'] = recent_scene['scenelocation']
      except:
        template_values['most_recent_scene_author'] = "local null"
        template_values['most_recent_scene_title'] = "local null"
        template_values['most_recent_scene_scenelocation'] = "local null"

      self.render_template('map.tmpl', template_values)

  def strip_tags(self, html):
      s = HTMLStripper()
      s.feed(html)
      return s.get_data()

  def get_most_recent_scene(self):
    print "Tryna get some new scenes XXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    try:
      gql_query = db.GqlQuery("SELECT * FROM PlacedLit ORDER BY ts DESC LIMIT 1")
    except Exception:
      print "Error yo"
      query_result = "Null"
    if gql_query:
      for scene in gql_query:
        print 'gql query ========================================'
        print scene
        recent_scene = dict()
        recent_scene['author'] = scene.author
        recent_scene['title'] =  scene.title
        recent_scene['scenelocation'] = scene.scenelocation
        return recent_scene

class HTMLStripper(HTMLParser):
  def __init__(self):
    self.reset()
    self.fed = []
  def handle_data(self, data):
    # data is the string to parse HTML out of
    self.fed.append(data)
  def get_data(self):
    return ''.join(self.fed)

class BlogHandler(baseapp.BaseAppHandler):
  # Gets the RSS feed of Placing Lits'blog using feedparser.parse

  def __init__(self):
    self.placing_lit_blog_rss = 'http://placingliterature.wordpress.com/feed/'

  def getRecentBlogPost(self):
    # returns necessary data for display on placing lit's featured content
    # section

    blog_feed = feedparser.parse(self.placing_lit_blog_rss)
    recent_blog = dict()
    recent_blog['recent_blog_title'] =  blog_feed.entries[0].title
    recent_blog['recent_blog_summary'] = blog_feed.entries[0].summary
    recent_blog['recent_blog_link'] = blog_feed.entries[0].links[0].href
    recent_blog['recent_blog_published'] = blog_feed.entries[0].published
    recent_blog['recent_blog_author'] = blog_feed.entries[0].author

    return recent_blog

  def stripHtmlTags(self, html):
    stripper = HTMLStripper()
    stripper.handle_data(html)
    return stripper.get_data()


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

  def get_nearby_places_json(self, lat=None, lng=None):
    places = placedlit.get_nearby_places(lat, lng, sorted=True)
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

urls = [
  ('/about', AboutHandler),
  ('/all', AllscenesHandler),
  ('/authorspotlight', AuthorSpotlightHandler),
  ('/funding', FundingHandler),
  ('/home', HomeHandler),
  ('/map/filter/(.*)/(.*)', MapFilterHandler),
  ('/map(/?.*)', MapHandler),
  ('/', MapHandler),
  ('/user/status', UserstatusHandler),
  ('/desktop/', NewhomeHandler),
  ('/admin/edit', AdminEditSceneHandler),
  ('/admin/menu', AdminMenuHandler),
  ('/oldhome', HomeHandler),
  ('/collections', CollectionsHandler)
]

app = webapp.WSGIApplication(urls, debug=True)
