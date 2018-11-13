"""
Web scrape Alcoholics Anonymous website for meeting details
========================================
This file web scrapes information about Alcoholics Anonymous
meetings in Great Britain, including location, time and
duration
Requirements
------------
:requires: bs4
:requires: urllib
:requires: selenium
:requires: time
:requires: pandas
Author
------
:author: Gaskyk
Version
-------
:version: 0.1
:date: 10-Sep-2018
"""

from bs4 import BeautifulSoup
from urllib.request import urlopen
from selenium import webdriver
from selenium.webdriver.support.ui import Select
import time
import pandas as pd

def get_area_list():
    """
    AA website requires knowing the area of meetings before meetings
    are displayed. This function gets a list of area codes for feeding
    into web scraping of meetings in areas later

    :return: area_list
    :rtype: list of strings of numbers
    """
    r = urlopen('https://www.alcoholics-anonymous.org.uk/aa-meetings/Find-a-Meeting').read()
    soup = BeautifulSoup(r, 'lxml')

    select_area_url = soup.find_all("select",{"id":"map-igroup"})
    options = select_area_url[0].find_all("option")

    area_list = []
    for i in options:
        area_list.append(i['value'])

    # There are no values for the options for larger areas eg. South West
    # So filter these out to keep only values in the list
    area_list = list(filter(lambda x: x != '', area_list))

    return area_list


def aa_scraping(area_value):
    """
    Function to extract meeting location and times from AA website
    for a specfic area value. Selenium is required to be used due
    to need to select elements from a drop-down menu and click
    'Search' button

    :param area_value: string value of an area such as Bournemouth District
    :type area_value: str

    :return: headers, main_text of location and times of meetings
    :rtype: Two Selenium WebElements for each of headers and main_text
    """
    # Launch web driver and go to website
    driver = webdriver.Chrome('C:/Program Files/ChromeDriver/chromedriver.exe')
    driver.get('https://www.alcoholics-anonymous.org.uk/aa-meetings/Find-a-Meeting')

    # Select area from drop-down menu
    select = Select(driver.find_element_by_id('map-igroup'))
    select.select_by_value(area_value)

    # Click 'search' button
    driver.find_element_by_class_name('cSubmit').click()

    # Wait for javascript to fully load
    driver.implicitly_wait(10)

    # Get required elements from page
    headers = driver.find_elements_by_tag_name('h3')
    main_text = driver.find_elements_by_tag_name('p')

    # Decode headers and main_text as lists not Selenium WebElements
    headers_decoded = [i.text for i in headers]
    main_text_decoded = [i.text for i in main_text]
    main_text_decoded = main_text_decoded[5:] # First 5 elements talk about cookies, general stuff

    # Quit driver
    driver.quit()

    return headers_decoded, main_text_decoded


# Get all area codes
area_list = get_area_list()

# Get all meetings in all areas
meeting_name = []
meeting_info = []
for i in ('31', '23', '29'):
    temp = aa_scraping(i)
    meeting_name.append(temp[0])
    meeting_info.append(temp[1])
    time.sleep(10)

# We have a list of lists. Convert this to one long list
all_names = [item for sublist in meeting_name for item in sublist]
all_info = [item for sublist in meeting_info for item in sublist]

def format_scrape_info(my_list):
    """
    Reformat output of web scraping to a pandas dataframe

    :param headers: output from web scraping AA website
    :type headers: list
    :return: Pandas DataFrame of web scraped data
    :rtype: Pandas DataFrame
    """

    # Split into addresses, times and postcodes
    addresses = [i.splitlines()[0] for i in my_list]
    times = [i.splitlines()[1] for i in my_list]
    postcodes = [i.splitlines()[2] for i in my_list]
    # Format of postcodes[0] is 'Postcode: POSTCODE'
    postcodes = [i.replace('Postcode: ', '') for i in postcodes]
    # Format of times[0] is 'Time: 18.00 - duration 1hr 15 mins
    times = [i.replace('Time: ', '') for i in times]

    meetings = pd.DataFrame({'addresses': addresses,
                             'postcodes': postcodes,
                             'times': times})
    return meetings

meetings_info_df = format_scrape_info(all_info)

def create_final_df(my_list, df):
    """
    Add meeting name to meeting info for final pandas dataframe

    :param headers: output from web scraping AA website
    :type headers: list
    :return: Pandas DataFrame of web scraped data
    :rtype: Pandas DataFrame
    """
    meeting_names = pd.DataFrame({'meeting_names': my_list})

    meetings = pd.concat([meeting_names, df], axis=1)

    return meetings

meetings_df = create_final_df(all_names, meetings_info_df)

# Import postcode to local authority lookup and merge
postcode_lookup = pd.read_csv('xx/NSPL_AUG_2018_UK.csv', usecols=['pcds', 'laua', 'lat', 'long'])
meetings = pd.merge(meetings_df, postcode_lookup, left_on='postcodes', right_on='pcds', how='left')

# Export to CSV
meetings_df.to_csv('xx/aa_meetings_formatted.csv', encoding='utf-8')


