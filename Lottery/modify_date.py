import pandas as pd
import os

from datetime import date


def int2date(argdate: int) -> str:

    year = int(argdate / 10000)
    month = int((argdate % 10000) / 100)
    day = int(argdate % 100)

    return date(year, month, day).strftime('%Y-%m-%d')


prices = pd.read_stata('./data/Prices_2015_2019.dta', chunksize=1000)

counter = 0
for chunk in prices:
    chunk['calendarid'] = [int2date(x) for x in chunk['calendarid']]

    if os.path.isfile('./data/prices.csv'):
        chunk.to_csv('./data/prices.csv', mode='a', header=False)
    else:
        chunk.to_csv('./data/prices.csv')

    counter += 1
    print(f'chunk {counter} done.')
