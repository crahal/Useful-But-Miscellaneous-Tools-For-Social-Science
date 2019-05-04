'''
Get venue details from a list of of foursquare venues
'''

import os
import logging
import pandas as pd
import time
import csv
import numpy as np
import foursquare


def setup_logging(logpath):
    if os.path.exists(logpath):
        if os.path.isfile(os.path.abspath(
                          os.path.join(logpath, 'foursquare_venues.log'))):
            os.remove(os.path.abspath(
                      os.path.join(logpath, 'foursquare_venues.log')))
    else:
        os.makedirs(logpath)
    logger = logging.getLogger('foursquare_venues')
    logger.setLevel(logging.DEBUG)
    fh = logging.FileHandler((os.path.abspath(
        os.path.join(logpath, 'foursquare_venues.log'))))
    fh.setLevel(logging.DEBUG)
    ch = logging.StreamHandler()
    ch.setLevel(logging.ERROR)
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    fh.setFormatter(formatter)
    ch.setFormatter(formatter)
    logger.addHandler(fh)
    logger.addHandler(ch)
    return logger


def make_unique(df1,df2):
    venues = pd.concat([pd.DataFrame(df_mv_v1['venue1'].unique(),
                                     columns=['venue']),
                        pd.DataFrame(df_mv_v2['venue1'].unique(),
                                     columns=['venue']),
                        pd.DataFrame(df_mv_v1['venue2'].unique(),
                                     columns=['venue']),
                        pd.DataFrame(df_mv_v2['venue2'].unique(),
                                     columns=['venue'])])
    unique_venues = venues['venue'].unique()                        
    return unique_venues


def load_token(token_path):
    try:
        with open(token_path, 'r') as file:
            return str(file.readline()).strip()
    except EnvironmentError:
        print('Error loading access token from file')


if __name__ == '__main__':
    datapath = os.path.abspath(os.path.join(__file__, '../..', 'data',
                                            'foursquare'))
    logpath = os.path.abspath(os.path.join(__file__, '../..', 'logging'))
    tokenpath = os.path.abspath(os.path.join(__file__, '../..', 'tokens'))
    logger = setup_logging(logpath)
    FS_ID = load_token(os.path.join(tokenpath, 'foursquare_id'))
    FS_SECRET = load_token(os.path.join(tokenpath, 'foursquare_secret'))
    logger.info('Loaded client secret and ID')
    df_mv_v1 = pd.read_csv(os.path.join(datapath, 'movements',
                                        'London_movements.csv'))
    df_mv_v2 = pd.read_csv(os.path.join(datapath, 'movements_v2',
                                        'London_movements_v2.csv'),
                           names=["venue1", "venue2", "month",
                                  "period", "checkins"])
    unique_venues = make_unique(df_mv_v1, df_mv_v2)
    logger.info('Created df.Series of %s unique venues.', len(unique_venues))
    client = foursquare.Foursquare(client_id='FS_ID',
                                   client_secret='FS_SECRET')
    with open(os.path.abspath(os.path.join(__file__, '../..', 'data',
                                           'foursquare',
                                           'unique_venues.tsv')),
                              'w') as fileout:
        foursquare_scraper = csv.writer(fileout, delimiter='\t', 
                                        lineterminator='\n')
        foursquare_scraper.writerow(['ID', 'name','categories',
                                     'shortcategories','address','lat',
                                     'long','postcode','rating', 'likes',
                                     'checkinsCount', 'usersCount',
                                     'tipCount'])
        client = foursquare.Foursquare(client_id=FS_ID,
                                       client_secret=FS_SECRET)
        index_iter = 0        
        while index_iter < len(unique_venues)+1:
            r = client.venues(unique_venues[0]) # trick to get rate_remaining
            if int(client.rate_remaining)>0:
                r = client.venues(unique_venues[index_iter])
                try:
                    name = r['venue']['name']
                except Exception as e:
                    logger.warning('Name not returned: %s', e)
                    name = np.nan
                try:
                    cats=''
                    shortcat=''
                    for cat in r['venue']['categories']:
                        cats = cats + ';' + cat['name']
                        shortcat = shortcat + ';' + cat['shortName']
                except Exception as e:
                    logger.warning('Cats not returned: %s', e)
                    cats = np.nan
                    shortcat = np.nan
                try:
                    addr = r['venue']['location']['address']
                except Exception as e:
                    logger.warning('Addr not returned: %s', e)
                    addr = np.nan
                try:
                    lat = r['venue']['location']['lat']
                except Exception as e:
                    logger.warning('Lat not returned: %s', e)                    
                    lat = np.nan
                try:
                    lng = r['venue']['location']['lng']
                except Exception as e:
                    logger.warning('lng not returned: %s', e)
                    lng = np.nan                    
                try:
                    pcode = r['venue']['location']['postalCode']
                except Exception as e:
                    logger.warning('postcode not returned: %s', e)
                    pcode = np.nan
                try:
                    rating = r['venue']['rating']
                except Exception as e:
                    logger.warning('rating not returned: %s', e)
                    rating = np.nan
                try:
                    likes = r['venue']['likes']['count']
                except Exception as e:
                    logger.warning('likes not returned: %s', e)
                    likes = np.nan
                try:
                    tipCount = r['venue']['stats']['tipCount']
                except Exception as e:
                    logger.warning('tipCount not returned: %s', e)
                    tipCount = np.nan       
                try:
                    usersCount = r['venue']['stats']['usersCount']
                except Exception as e:
                    logger.warning('users not returned: %s', e)
                    usersCount = np.nan       
                try:
                    checkinsCount = r['venue']['stats']['checkinsCount']
                except Exception as e:
                    logger.warning('checkins not returned: %s', e)
                    checkinsCount = np.nan       
                index_iter += 1
                foursquare_scraper.writerow([unique_venues[index_iter], name,
                                             cats, shortcat, addr, lat, lng,
                                             pcode, rating, likes,
                                             checkinsCount, usersCount,
                                             tipCount])
                logger.info('Grabbed data for: %s', unique_venues[index_iter])
                time.sleep(5)
            else:
                time.sleep(100)
            
        
        
    #X-RateLimit-Remaining and X-RateLimit-Limit HTTP headers of API responses.
    
