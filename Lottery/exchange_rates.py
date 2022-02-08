import pandas as pd
import numpy as np
import DatastreamDSWS as DSWS
ds = DSWS.Datastream(username="ZUIO002", password="VISOR474")


tickers = {
    'AUD': ['AUCHFSP'],
    'BRL': ['TBRLCHF'],
    'CAD': ['BCCHFCA', 'CNCHFSC'],
    'CZK': ['PRCHFSP'],
    'DKK': ['DKCHFSP'],
    'EUR': ['SWECBSP'],
    'GBP': ['SWSTBOE'],
    'GBX': ['SWSTBOE'],
    'HKD': ['HKCGFSP'],
    'HRK': ['CTCHFSP'],
    'HUF': ['HNCHFNB'],
    'IDR': [''],
    'ILS': ['ISCHFSP'],
    'JPY': ['TRCHJPC'],
    'KRW': ['KOCHFSP'],
    'LKR': [''],
    'LVL': [''],
    'MXN': ['MXSWFSP'],
    'MYR': ['MLCHFSP'],
    'NOK': ['NWCHFSP'],
    'NZD': [''],
    'PHP': ['PHCHFSP'],
    'PLN': ['POCHFSP'],
    'RUB': ['RSCHFSP'],
    'SEK': ['SDCHFSP'],
    'SGD': ['TRSGCHC'],
    'THB': ['THCHFSP'],
    'TRY': ['TKCHFSP'],
    'USD': ['TDCHFSP'],
    'ZAR': ['']
}

reverse = ['CAD', 'CZK', 'DKK', 'HKD', 'HRK', 'HUF', 'ILS', 'JPY', 'KRW',
           'LVL', 'MXN', 'MYR', 'NOK', 'PHP', 'RUB', 'SEK', 'THB', 'TRY', 'PLN']
_100 = ['DKK', 'SEK']
__100 = ['GBX']

# !!! ATTENTION
# -> DKK, SKK per 100CHF
# -> CZE, DKK, HKD, HKR, HUF, ILS, JPY, KRW, LVL, MXN, MYR, NOK, PHP, RUB, SEK, THB, TRY other way round
# -> IDR, NZD, LKR, ZAR no exchange rate

NUM_COLS = len(tickers.keys())

curr_data = []

for curr in tickers:
    if tickers[curr][0] == "":
        curr_data.append([None])
        continue

    if curr == 'CAD':
        new_data = ds.get_data(
            tickers=tickers[curr][0], fields=['ER'], start="2014-01-01", freq="D")
        old_data = ds.get_data(
            tickers=tickers[curr][1], fields=['ER'], start="2014-01-01", freq="D")
        dates = old_data.index
        new_data = np.squeeze(new_data.values)
        old_data = np.squeeze(old_data.values)
        nan_mask_old = np.isnan(old_data)
        old_data[nan_mask_old] = new_data[nan_mask_old]

        values = old_data

    else:
        price_data = ds.get_data(
            tickers=tickers[curr][0], fields=['ER'], start="2014-01-01", freq="D")
        values = np.squeeze(price_data.values)
        dates = price_data.index

    if curr in reverse:
        values = [1/x for x in values]

    if curr in _100:
        values = [x*100 for x in values]

    if curr in __100:
        values = [x/100 for x in values]

    # print(values)
    curr_data.append(values)
    print(curr, ' done.')
    print('--------------------')

df = pd.DataFrame(curr_data).transpose()
df.columns = tickers.keys()
df['date'] = dates
df['date'] = pd.to_datetime(
    df['date'], infer_datetime_format=True)
df = df.dropna(axis=1)

wk = pd.read_csv('./data/Wechselkurse.csv')
wk = wk.iloc[:, [6, 5, 7, 9, 10, 12, 14]]
wk = wk.drop(axis=0, index=0)
wk = wk.rename(columns={'Unnamed: 6': 'date'})
wk['IDR'] = wk['IDR'] / 10000
wk['date'] = pd.to_datetime(
    wk['date'], infer_datetime_format=True)

comb = wk.merge(df, how='left', left_on=[
    'date'], right_on=['date'])
comb.to_csv('./data/exchange_rates.csv')

print('Successful execution.')
