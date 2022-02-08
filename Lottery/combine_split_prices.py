import pandas as pd
import datetime
import os
import sys

prices = pd.read_csv('./data/prices.csv', chunksize=10000,
                     infer_datetime_format=True, parse_dates=['calendarid'])
prices_update = pd.read_csv('./data/prices_update.csv', chunksize=10000,
                            infer_datetime_format=True, parse_dates=['calendarid'])
factor_returns = pd.read_csv('./data/factorReturns.csv', chunksize=10000,
                             infer_datetime_format=True, parse_dates=['datenum'])

data = 'factorReturns'


def check_dates(start_date, end_date, list_of_dates):
    mask_after_start = list_of_dates >= start_date
    mask_before_end = list_of_dates <= end_date

    return mask_after_start * mask_before_end


counter = 0
for chunk in factor_returns:
    dates = chunk['datenum']

    mask_2015 = check_dates(datetime.datetime(
        2015, 1, 1), datetime.datetime(2015, 12, 31), dates)
    mask_2016 = check_dates(datetime.datetime(
        2016, 1, 1), datetime.datetime(2016, 12, 31), dates)
    mask_2017 = check_dates(datetime.datetime(
        2017, 1, 1), datetime.datetime(2017, 12, 31), dates)
    mask_2018 = check_dates(datetime.datetime(
        2018, 1, 1), datetime.datetime(2018, 12, 31), dates)
    mask_2019 = check_dates(datetime.datetime(
        2019, 1, 1), datetime.datetime(2019, 12, 31), dates)
    mask_2020 = check_dates(datetime.datetime(
        2020, 1, 1), datetime.datetime(2020, 12, 31), dates)
    mask_2021 = check_dates(datetime.datetime(
        2021, 1, 1), datetime.datetime(2021, 12, 31), dates)

    if os.path.isfile(f'./data/{data}_2015.csv'):
        chunk[mask_2015].to_csv(
            f'./data/{data}_2015.csv', mode='a', header=False)
    else:
        chunk[mask_2015].to_csv(f'./data/{data}_2015.csv')

    if os.path.isfile(f'./data/{data}_2016.csv'):
        chunk[mask_2016].to_csv(
            f'./data/{data}_2016.csv', mode='a', header=False)
    else:
        chunk[mask_2016].to_csv(f'./data/{data}_2016.csv')

    if os.path.isfile(f'./data/{data}_2017.csv'):
        chunk[mask_2017].to_csv(
            f'./data/{data}_2017.csv', mode='a', header=False)
    else:
        chunk[mask_2017].to_csv(f'./data/{data}_2017.csv')

    if os.path.isfile(f'./data/{data}_2018.csv'):
        chunk[mask_2018].to_csv(
            f'./data/{data}_2018.csv', mode='a', header=False)
    else:
        chunk[mask_2018].to_csv(f'./data/{data}_2018.csv')

    if os.path.isfile(f'./data/{data}_2019.csv'):
        chunk[mask_2019].to_csv(
            f'./data/{data}_2019.csv', mode='a', header=False)
    else:
        chunk[mask_2019].to_csv(f'./data/{data}_2019.csv')

    if os.path.isfile(f'./data/{data}_2020.csv'):
        chunk[mask_2020].to_csv(
            f'./data/{data}_2020.csv', mode='a', header=False)
    else:
        chunk[mask_2020].to_csv(f'./data/{data}_2020.csv')

    if os.path.isfile(f'./data/{data}_2021.csv'):
        chunk[mask_2020].to_csv(
            f'./data/{data}_2021.csv', mode='a', header=False)
    else:
        chunk[mask_2020].to_csv(f'./data/{data}_2021.csv')

    counter += 1
    print(f'chunk {counter} done.')
