
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


short_dict = {x: x*5 for x in range(1, 100)}

long_dict = {x: x*5 for x in range(1, 10000000)}

print(short_dict)
