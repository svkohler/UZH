import pandas as pd
import numpy as np
import pickle
import sys
from tqdm import tqdm
import os


def is_lottery(row, dict, year, agg_stats):
    # try to find isin in dictionary -> when not match return 'data_missing'
    try:
        results = dict[year][row['ISIN']]
        # check if conditions for lottery stock are met
        if results['std'] >= agg_stats[year]['std'] and results['skew'] >= agg_stats[year]['skew'] and results['last_price'][1] <= agg_stats[year]['last_price']:
            return 'YES'
        else:
            return 'NO'
    except:
        results = 'data_missing'
    return results


YEARS = [2015, 2016, 2017, 2018, 2019, 2020, 2021]

AGGREGATE_STATS = {}

with open('./data/isin_lottery.pickle', 'rb') as file:
    isin_lottery = pickle.load(file)


for year in list(isin_lottery.keys())[1:]:
    STD = []
    SKEW = []
    LAST = []
    # collect data
    for key in isin_lottery[year].keys():
        STD.append(isin_lottery[year][key]['std'])
        SKEW.append(isin_lottery[year][key]['skew'])
        LAST.append(isin_lottery[year][key]['last_price'][1])

    # save the relevant quantiles
    AGGREGATE_STATS[year] = {
        'std': np.quantile(STD, 0.8),
        'skew': np.quantile(SKEW, 0.8),
        'last_price': np.quantile(LAST, 0.2)
    }

# go through securities chunkwise
securities = pd.read_csv('./data/Securities.csv', sep=';', encoding='utf-16',
                         on_bad_lines='skip', low_memory=False, chunksize=100000)


# process data
for i, chunk in enumerate(securities):
    for year in YEARS:
        chunk[f'lottery_{year}'] = chunk.apply(
            is_lottery, args=(isin_lottery, year, AGGREGATE_STATS), axis=1)

    if os.path.isfile(f'./data/results_lottery.csv'):
        chunk.to_csv(f'./data/results_lottery.csv', mode='a', header=False)
    else:
        chunk.to_csv(f'./data/results_lottery.csv')

    print(f'chunk {i} done')
