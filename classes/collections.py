""" Datastore model for scene collections. """
#  pylint: disable=R0904, W0403

import logging

from google.appengine.ext import db

FEATURED = dict()
FEATURED['catalan'] = {
  'url': 'http://www.espaisescrits.cat/',
  'user': 'info@espaisescrits.cat',
  'center': {'lat': '41.3866336905', 'lng': '2.1750998497'}
}
FEATURED['slq'] = {
  'url': 'http://slq.qld.gov.au',
  'user': 'webmanager@slq.qld.gov.au',
  'center': {'lat': '-25.0246396949', 'lng': '136.142578125'}}

FEATURED['christianlit'] = {'url': 'http://www.placingliterature.com',
                            'user': 'info@placingliterature.com',
                            'center': {'lat': '41.8297953655', 'lng': '-87.6234490632'}}
FEATURED['amistad'] = {'url': 'http://www.placingliterature.com',
                       'user': 'info@placingliterature.com',
                       'center': {'lat': '41.8297953655', 'lng': '-87.6234490632'}}


class Collection(db.Model):
  """ Collections of scenes. Collections are keyed by name """
  name = db.StringProperty()
  url = db.LinkProperty()
  scenes = db.ListProperty(db.Key)

  def add_scene(self, scene_key):
    """ add a scene to this collection """
    self.scenes.append(scene_key)
    self.put()

  def create_or_update(self, collection_name):
    """ named collections is updated or created if key is not found """
    collection = self.get_by_key_name(collection_name)
    if not collection:
      collection = Collection(key_name=collection_name)
      if collection_name in FEATURED:
        collection.url = FEATURED[collection_name]['url']
        collection.put()
    return collection

  def get_named(self, collection_name):
    """ return previously existing collection or None """
    #logging.info('wa_collection:  collection_name: ' + collection_name)

    #esult = self.get_by_key_name(collection_name)
    #logging.info('wa_collection: self.get_by_key_name(collection_name) returns: '  + result)
    return self.get_by_key_name(collection_name)
