import pandas as pd
import numpy as np
import sys
from tqdm import tqdm
from sklearn.linear_model import LinearRegression
import scipy
import time
import pickle
import os

years = [2015, 2016, 2017, 2018, 2019, 2020, 2021]

if os.path.isfile('./data/isin_lottery.pickle'):
    with open('./data/isin_lottery.pickle', 'rb') as file:
        isin_lottery = pickle.load(file)
else:
    isin_lottery = {'info': {
        'year': 2000,
        'chunk': 0
    }
    }

# go year by year since Lottery characteristic is computed on a yearly basis
for year in years:
    # if year has already been processed -> skip
    if year < isin_lottery['info']['year']:
        continue
    isin_lottery[year] = {}
    # process securities data chunk by chunk
    securities = pd.read_csv('./data/Securities.csv', sep=';', encoding='utf-16',
                             on_bad_lines='skip', low_memory=False, chunksize=100000)
    # load all price data for a given year
    prices = pd.read_csv(
        f'./data/prices_{year}.csv', infer_datetime_format=True, parse_dates=['calendarid'])

    factors = pd.read_csv(
        f'./data/factorReturns_{year}.csv', infer_datetime_format=True, parse_dates=['datenum'])
    # save the isins in a dictionary for faster look-up time
    prices_isin_dict = {x: x for x in prices['isin'].values}
    # initialize counters
    chunk_counter = 0
    isin_counter = 0
    for i, chunk in enumerate(securities):
        # if chunk has already been processed -> skip
        if i < isin_lottery['info']['chunk']:
            continue
        # isolate ISIN values from securities
        isins = chunk['ISIN'].values
        # loop through ISINs and compute return metrics
        for isin in tqdm(isins):
            # check if security ISIN is present in prices data
            if isin in prices_isin_dict.keys():
                # start_time = time.time()
                # get all rows with the matching isin
                relevant_prices = prices[prices['isin'].values == isin]
                # if fewer than 25 rows then skip
                if len(relevant_prices) < 25:
                    continue
                # drop duplicates if multiple rows on same date
                relevant_prices = relevant_prices.drop_duplicates(
                    subset=['calendarid'], keep='first')
                # sort using date
                relevant_prices = relevant_prices.sort_values(
                    by=['calendarid'])
                # calculate return and append new column (add small amount for numeric stability)
                relevant_prices['returnschf'] = (
                    relevant_prices['closepricechf']-relevant_prices['closepricechf'].shift(1))/(relevant_prices['closepricechf'].shift(1)+1e-9)
                # merge with marketfactors using dates
                reg_data = factors.merge(relevant_prices, how='left', left_on=[
                                         'datenum'], right_on=['calendarid'])
                # drop NA values
                reg_data = reg_data.dropna(subset=['returnschf'])
                # perform linear Regression
                model = LinearRegression()
                model.fit(
                    X=reg_data[['mktrf', 'smb', 'hml', 'mom']], y=reg_data['returnschf'])
                predictions = model.predict(
                    X=reg_data[['mktrf', 'smb', 'hml', 'mom']])
                # extract residuals
                resid = reg_data['returnschf'] - predictions
                # calculate statistics
                std = np.std(resid)
                skew = scipy.stats.skew(resid)
                isin_lottery[year][isin] = {'std': std,
                                            'skew': skew,
                                            'last_price': reg_data['closepricechf'].values[-1]}
                isin_counter += 1
                # print(time.time()-start_time)
        chunk_counter += 1
        isin_lottery['info'] = {
            'year': year,
            'chunk': chunk_counter
        }
        with open('./data/isin_lottery.pickle', 'wb') as file:
            pickle.dump(isin_lottery, file)
        if chunk_counter % 50 == 0:
            print(f'chunk {chunk_counter} done')
    print(f'number of isin found in year {year}: {isin_counter}')
