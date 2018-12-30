"""
An amended version of Linda Li's work for her dissertation in 2018/19
based on my own earlier script from Aug 2016. Modified to save data into
sqlite, listen for multiple tags on multiple different subjects at once,
catch errors more robustly, logging, etc.

Requires: auth.txt: a plain text file with your credentials
          keywords.txt: a list of the keywords which youre listening for

Last modified: Dec 2018
"""

import tweepy
from ssl import SSLError
from requests.exceptions import Timeout, ConnectionError
from urllib3.exceptions import ReadTimeoutError
from tweepy import OAuthHandler
import time
import sqlite3 as sqlite
import logging
from tweepy.streaming import StreamListener

logging.basicConfig(level=logging.INFO, datefmt='%a, %d %b %Y %H:%M:%S',
                    format='%(asctime)s %(levelname)s %(message)s',
                    filename='twitter_scraper.log')


def load_token(textfile):
    '''
    note: the load_token takes a .txt file with these auth in sequence
    consumer key, consumer secret, access token, access secret
    '''
    try:
        with open(textfile, 'r') as file:
            auth = file.readlines()
            keys = []
            for i in auth:
                i = str(i).strip()
                keys.append(i)
        return keys
    except EnvironmentError:
        print('Error loading access token from file')


class MyListener(StreamListener):
    def on_status(self, status):
        global hourscounter
        global timestamp_previous
        timestamp = time.strftime("%Y%m%d_%H")
        table = None
        for k in keywords:
            if k in status.text:
                table = 'twitters'
                break
        if table is not None:
            if timestamp != timestamp_previous:
                hourscounter += 1
                logging.info('Stream has been up for:' +
                             str(hourscounter) +
                             ' hours')
            status.text = status.text.replace('\n', ' ')
            status.text = status.text.replace('\r', ' ')
            if status.user.description is not None:
                status.user.description = status.user.description.\
                                          replace('\n', ' ')
                status.user.description = status.user.description.\
                                          replace('\r', ' ')
            retweet_id = ''
            retweet_uid = ''
            retweet = ''
            text = status.text
            user_info = (status.user.id_str,
                         status.user.screen_name,
                         status.user.name,
                         status.user.description,
                         status.user.location,
                         status.user.followers_count,
                         status.user.friends_count,
                         status.user.created_at)
            uid = status.user.id_str
            c.execute('''SELECT * FROM users WHERE user_id LIKE '''+uid)
            re = c.fetchall()
            if len(re) == 0:
                try:
                    c.execute(''' insert into users
                          (user_id, user_screen_name, username,
                          user_description,
                          user_location, user_followers,
                          user_friends, user_created_at)
                          values(?, ?, ?, ?, ?, ?, ?, ?)''',  user_info)
                except Exception as e:
                    logging.warning('Error when scraping user info:' +
                                    str(e))
            if status.truncated is True:
                text = status.extended_tweet['full_text']
            if hasattr(status, 'retweeted_status'):
                retweet_id = status.retweeted_status.id_str
                retweet_uid = status.retweeted_status.user.id_str
                retweet = status.retweeted_status.text
            if hasattr(status, 'quote_status'):
                retweet_id = status.quoted_status.id_str
                retweet_uid = status.quoted_status.user.id_str
                retweet = status.quoted_status.text
            twitter = (status.id_str,
                       status.user.id_str,
                       status.user.screen_name,
                       status.user.name,
                       status.created_at, text,
                       status.in_reply_to_user_id_str,
                       status.in_reply_to_screen_name,
                       retweet_id, retweet_uid, retweet)
            statusid = status.id_str
            c.execute('''SELECT * FROM twitters WHERE id LIKE ''' + statusid)
            re_new = c.fetchall()
            if len(re_new) == 0:
                try:
                    order = 'insert into ' + table + '''(id, user_id,
                         user_screen_name,
                         username,
                         created_at,
                         fulltext,
                         in_reply_to_userid,
                         in_reply_to_userscreename,
                         retweet_uid,
                         retweet_id,
                         retweet)
                    VALUES (?,?,?,?,?,?,?,?,?,?,?)'''
                    c.execute(order, twitter)
                except Exception as e:
                    logging.warning('Encountered error when scraping twitter' +
                                    str(e))
        conn.commit()
        timestamp_previous = time.strftime("%Y%m%d_%H")

    def on_error(self, status):
        logging.warning(status)


try:
    auth = load_token("auth.txt")
    costumer_token = auth[0]
    costumer_key = auth[1]
    access_token = auth[2]
    access_key = auth[3]
    auth = OAuthHandler(costumer_token, costumer_key)
    auth.set_access_token(access_token, access_key)
    api = tweepy.API(auth,
                     wait_on_rate_limit=True,
                     wait_on_rate_limit_notify=True)
    timestamp_previous = time.strftime("%Y%m%d_%H")
    hourscounter = 0
    conn = sqlite.connect('brexit.sqlite',  check_same_thread=False)
    c = conn.cursor()
    c.execute('''CREATE TABLE if NOT EXISTS users
                 (user_id unique, user_screen_name text, username text,
                 user_description text, user_location text, user_followers int,
                 user_friends int, user_created_at text)''')
    c.execute('''CREATE TABLE if NOT EXISTS twitters
                 (id unique, user_id text, user_screen_name text,
                 username text, created_at text, fulltext text,
                 in_reply_to_userid text, in_reply_to_userscreename text,
                 retweet_uid text, retweet_id text, retweet text)''')
    keywords = load_token('keywords.txt')
    twitter_stream = tweepy.Stream(auth, MyListener())
    while not twitter_stream.running:
        try:
            twitter_stream.filter(track=keywords, async=False)
        except (Timeout, SSLError, ReadTimeoutError, ConnectionError) as e:
            logging.error('Network error occured:', str(e))
            time.sleep(120)
        except Exception as e:
            logging.error('Unexpected Error!', str(e))
            time.sleep(120)
        finally:
            logging.info('Stream has crashed, restarting now!')
            time.sleep(120)
    logging.critical('Macro error Type 1...')
except Exception as e:
    time.sleep(120)
    logging.critical('Macro error Type 2...')
