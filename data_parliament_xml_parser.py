# -*- coding: utf-8 -*-
"""
Created on Wed Mar 28 18:43:05 2018

A basic example of parsing the xml from data.parliament
"""
import requests
import xml.etree.ElementTree as ET

base = 'http://data.parliament.uk/membersdataplatform/'
service = 'services/mnis/members/query/'
query = 'holdsgovernmentpost=true%7Cmembership=all/GovernmentPosts/'
r = requests.get(base + service + query)

root = ET.fromstring(r.text)

myfile = open('listofmembers.txt', 'w')
for s in root:
    if s.find('DisplayAs').text is not None:
        DisplayAs = s.find('DisplayAs').text
    else:
        DisplayAs = 'N/A'
    if s.find('FullTitle').text is not None:
        FullTitle = s.find('FullTitle').text
    else:
        FullTitle = 'N/A'
    if s.find('DateOfBirth').text is not None:
        DateOfBirth = s.find('DateOfBirth').text
    else:
        DateOfBirth = 'N/A'
    if s.find('Gender') is not None:
        Gender = s.find('Gender').text
    else:
        Gender = 'N/A'
    if s.find('House') is not None:
        House = s.find('House').text
    else:
        House = 'N/A'
    if s.find('HouseStartDate').text is not None:
        HouseStartDate = s.find('HouseStartDate').text
    else:
        HouseStartDate = 'N/A'
    for posts in s.find('GovernmentPosts'):
        if posts.find('Name').text is not None:
            PostName = posts.find('Name').text
        else:
            PostName = 'N/A'
        if posts.find('StartDate').text is not None:
            PostStart = posts.find('StartDate').text
        else:
            PostStart = 'N/A'
        myfile.writelines(DisplayAs + '\t' + FullTitle + '\t' +
                          DateOfBirth + '\t' + Gender + '\t' + House + '\t' +
                          HouseStartDate + '\t' + PostName + '\t' + PostStart + '\n')
myfile.close()
