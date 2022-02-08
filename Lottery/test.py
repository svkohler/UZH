
from operator import index
import pandas as pd
import numpy as np
from tqdm import tqdm

import sys

# isins = []
# isins_prices = []

# securities = pd.read_csv('./data/Securities.csv', sep=';', encoding='utf-16',
#                          on_bad_lines='skip', low_memory=False, chunksize=100000)

# prices = pd.read_csv('./data/prices.csv', chunksize=100000)

# for chunk in tqdm(securities):
#     isins.extend(chunk['ISIN'].values)
# for chunk in tqdm(prices):
#     isins_prices.extend(chunk['isin'].values)

# counter = 0
# for isin in tqdm(isins):
#     print('ISIN from sec file: ', isin)
#     if isin in isins_prices:
#         idx = isins_prices.index(isin)
#         print('ISIN from prices file', isins_prices[idx])
#         counter += 1
#         print(counter)


# short_dict = {x: x*5 for x in range(1, 100)}

# long_dict = {x: x*5 for x in range(1, 10000000)}

# print(short_dict)

# from datetime import datetime


# def int2date(argdate: int) -> str:

#     year = int(argdate / 10000)
#     month = int((argdate % 10000) / 100)
#     day = int(argdate % 100)

#     return date(year, month, day).strftime('%Y-%m-%d')


# table = pd.read_csv('./data/Wechselkurse.csv')

# table_mod = table.iloc[:, [6, 1, 3, 5, 7, 9, 10, 12, 14]]

# table_mod = table_mod.drop(axis=0, index=0)

# table_mod = table_mod.rename(columns={'Unnamed: 6': 'date'})

# table_mod['date'] = pd.to_datetime(
#     table_mod['date'], infer_datetime_format=True)

# print(type(table_mod['date'].values[0]))

# print(table_mod)

# er = pd.read_csv('./data/exchange_rates.csv', index_col=0)

# print(er)

# er['date'] = pd.to_datetime(
#     er['date'], infer_datetime_format=True)

# er = er.dropna(axis=1)

# er = er.drop(['Unnamed: 0'], axis=1)

# print(type(er['date'].values[0]))


# comb = table_mod.merge(er, how='left', left_on=[
#                        'date'], right_on=['date'])

# print(comb.iloc[:, :10])

# print(comb.iloc[:, 10:])


# p = pd.read_csv('./data/prices_2015.csv')

# factors = pd.read_csv('./data/factorReturns_2015.csv')

# relevant_prices = p[p['isin'].values == 'DE0005402614']

# relevant_prices = relevant_prices.drop_duplicates(
#     subset=['calendarid'], keep='first')
# # sort using date
# relevant_prices = relevant_prices.sort_values(
#     by=['calendarid'])

# relevant_prices['returnschf'] = (
#     relevant_prices['closepricechf']-relevant_prices['closepricechf'].shift(1))/(relevant_prices['closepricechf'].shift(1)+1e-9)

# reg_data = factors.merge(relevant_prices, how='left', left_on=[
#     'datenum'], right_on=['calendarid'])

# print(relevant_prices)

# print(reg_data)

arr = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

print(np.quantile(arr, 0.2))
