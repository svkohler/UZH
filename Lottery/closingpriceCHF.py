import pandas as pd
import datetime
from datetime import date
import os
import time


def int2date(argdate: int) -> str:

    year = int(argdate / 10000)
    month = int((argdate % 10000) / 100)
    day = int(argdate % 100)

    return date(year, month, day).strftime('%Y-%m-%d')


CHUNKSIZE = 100000

prices_update = pd.read_stata(
    './data/Prices_UpdateOct2021_Clean.dta', chunksize=CHUNKSIZE)

EX_RAT = pd.read_csv('./data/exchange_rates.csv')


def get_price(row):
    curr = row['currency']

    if curr == "CHF":
        return row['closeprice']
    elif curr in ['IDR', 'NZD', 'LKR', 'ZAR']:
        return None
    date_ = row['calendarid']
    rates = EX_RAT[['date', curr]]
    spot_rate = rates[rates['date'] == date_][curr]

    result = spot_rate * row['closeprice']

    return result.values[0]


counter = 0
for chunk in prices_update:

    chunk['calendarid'] = [int2date(x) for x in chunk['calendarid']]
    chunk['closepricechf'] = chunk.apply(get_price, axis=1)

    if os.path.isfile('./data/prices_update.csv'):
        chunk.to_csv('./data/prices_update.csv', mode='a', header=False, columns=[
                     'calendarid', 'isin', 'currency', 'closeprice', 'closepricechf', 'volume', 'yr'])
    else:
        chunk.to_csv('./data/prices_update.csv', columns=[
                     'calendarid', 'isin', 'currency', 'closeprice', 'closepricechf', 'volume', 'yr'])
    counter += 1
    print(f'chunk {counter} done.')
