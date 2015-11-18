"""
Retrieve blog posts from Wordpress RSS.
"""
# pylint: disable=R0904, R0914, C0103

import logging

import xml.etree.ElementTree as et

from google.appengine.ext import webapp
from google.appengine.api import urlfetch

from handlers.abstracts import baseapp
from classes import blogposts
import json, time, datetime

POST_COUNT = blogposts.DEFAULT_LIMIT  # number of posts to display
BLOG_FEED_URL = 'http://placingliterature.wordpress.com/feed/'


class BlogpostsHandler(baseapp.BaseAppHandler):
  """ request handler for blog post admin """
  def get(self):
    """ update blogposts for home page """
    fetch_headers = {'Cache-Control': 'no-cache,max-age=300',
                     'Pragma': 'no-cache'}
    result = urlfetch.fetch(BLOG_FEED_URL, None, urlfetch.GET, fetch_headers)
    logging.info(str(result.status_code) + ' ' + str(result.headers))
    poststring = str(result.content)
    posts = et.fromstring(poststring)
    link_format = '<a href="{}">{}</a><br/>'
    alllinks = []
    for item in posts.iter('item'):
      item_title = item.find('title').text
      item_link = item.find('link').text
      item_pub_date = item.find('pubDate').text
      item_description = item.find('description').text
      bloglink = link_format.format(item_link, item_title)
      alllinks.append(bloglink)
      blog_data = {'title': item_title, 'link': item_link,
                   'pub_date': item_pub_date, 'description': item_description}
      blogposts.Blogpost.create_from_dict(blog_data)

    links = alllinks[:POST_COUNT]
    for link in links:
      self.response.out.write(link)

  @staticmethod
  def posts_for_display():
    """ used by page handlers to get posts for display """
    posts = blogposts.Blogpost.get_newest_posts()
    return posts


class BlogpostsNewestHandler(baseapp.BaseAppHandler):
    def get(self):
        newest_post = blogposts.Blogpost.get_newest_posts(1)
        print "this is the newest blog post"
        print newest_post
        newest_post = newest_post.next()

        newest_post_json = json.dumps({"newest_post_title": newest_post.title,
                            "newest_post_link": newest_post.link,
                            "newest_post_pub_date": newest_post.pub_date.strftime("%Y-%m-%d %H:%M:%S"),
                            #"newest_post_pub_date": datetime.datetime.strptime(newest_post.pub_date, "%m-%j-%Y"),
                            #"newest_post_pub_date": time.strftime("%m-%j-%Y", newest_post.pub_date),
                            "newest_post_description": newest_post.description})
        '''
        newest_post_values = ["newest_post_title": newest_post.title,
                            "newest_post_pub_date": newest_post.pub_date,
                            "newest_post_description": newest_post.description,
                            ]
        '''
        #newest_post_json = json.dumps(newest_post_values)

        self.response.out.write(newest_post_json)



urls = [
  ('/blog/update', BlogpostsHandler),
  ('/blog/latest', BlogpostsNewestHandler)
]


app = webapp.WSGIApplication(urls, debug="True")
