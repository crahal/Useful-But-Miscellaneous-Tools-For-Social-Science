    # -*- coding: utf-8 -*-
"""
Listen to Twitter for multiple tags on multiple different subjects at once.

Set:	yourtagone and yourtagtwo for firstthing
	yourtagthree and yourtagfour for secondthing
	api keys

Last modified: August 2016

"""
import tweepy
from tweepy import OAuthHandler
import time
import pandas
import csv
import json
import sys

consumer_key = ''
consumer_secret = ''
access_token = ''
access_secret = ''
auth = OAuthHandler(consumer_key, consumer_secret)
auth.set_access_token(access_token, access_secret)
api = tweepy.API(auth)
from tweepy import Stream
from tweepy.streaming import StreamListener
timestamp_previous= time.strftime("%Y%m%d_%H")
hourscounter=0

class MyListener(StreamListener):
    def on_status(self, status):
        global hourscounter
        global timestamp_previous
        timestamp= time.strftime("%Y%m%d_%H")
        location=None
        if 'yourtagone' in status.text or 'yourtagtwo' in status.text:
            location='firstthing\\twitterdata\\main\\'
        elif 'yourtagthree' in status.text or 'yourtagfour' in status.text:
            location='secondthing\\twitterdata\\main\\'
        if location is not None:
            with open(location+'%s.csv' % timestamp, 'a', encoding='utf8',newline='') as f:
                if timestamp!=timestamp_previous:
                    hourscounter+=1
                    print('Stream has been up for:',hourscounter,' hours')
                writer = csv.writer(f)
                status.text=status.text.replace('\n', ' ')
                status.text=status.text.replace('\r', ' ')
                if status.user.description is not None:
                    status.user.description=status.user.description.replace('\n', ' ')
                    status.user.description=status.user.description.replace('\r', ' ')
                results = [status.id_str, status.created_at,status.user.screen_name,status.user.name,
				status.user.description,status.user.statuses_count,status.user.location,
				status.user.followers_count,status.user.friends_count,status.user.created_at,status.text,status.lang]
                writer.writerow(results) 
        timestamp_previous=time.strftime("%Y%m%d_%H")
    def on_error(self, status):
        print(status)
twitter_stream = Stream(auth, MyListener())
while True:
    try: 
        twitter_stream.filter(track=['yourtagone','yourtagtwo','yourtagthree','yourtagfour'])
    except:
        e = sys.exc_info()[0]
        print('ERROR:',e) 
        continue
