# import all necessary libraries
import warnings
import pandas as pd
import numpy as np
from tqdm import tqdm
import pickle
import os
import math

# load data
os.chdir('/home/svkohler/OneDrive/Desktop/UZH/Repo/Distance/data')
SEs = pd.read_csv('stock_ex.csv', index_col=0, names=['SE', 'city', 'iso3'])
adr = pd.read_csv('Compustat_Addresses.csv', low_memory=False)[
    ['datadate', 'isin', 'conm', 'fic', 'city']]
adr_US = pd.read_csv('Compustat_Addresses_US.csv', low_memory=False)[
    ['datadate', 'cusip', 'conm', 'fic', 'city']]
smi_adr = pd.read_csv('smi_adr.csv')
sec = pd.read_csv('Securities.csv', sep=';', encoding='utf-16',
                  on_bad_lines='skip', low_memory=False)
cities = pd.read_csv('worldcities.csv')
country_codes = pd.read_csv('cc.csv', sep='\t', header=None)[2].values

# flags
pre_calc = False

# drop rows in securities table where ISIN == nan and make column names to lower case
sec.columns = sec.columns.str.lower()
sec = sec.dropna(subset=['isin', 'symbol'])


def firstx(x, length):
    return x[:length]


# clean up adress data table such that there is one line per ISIN/CUSIP
pre_calc = True
if not pre_calc:
    # drop all rows with no isin
    adr = adr.drop(adr[adr['isin'].isnull()].index)
    # loop through all unique isins and take last row of subtable since this is the newest datapoint per isin.
    idx = []
    for isin in tqdm(adr['isin'].unique()):
        idx.append(adr[adr['isin'] == isin].index.values[-1])
    adr = adr.loc[idx]
    adr.to_csv('adr_c.csv', index=False)

if not pre_calc:
    # drop all rows with no cusip
    adr_US = adr_US.drop(adr_US[adr_US['cusip'].isnull()].index)
    # loop through all unique cusips and take last row of subtable since this is the newest datapoint per cusip.
    idx = []
    for cusip in tqdm(adr_US['cusip'].unique()):
        idx.append(adr_US[adr_US['cusip'] == cusip].index.values[-1])
    adr_US = adr_US.loc[idx]
    # extract the shortened cusips and append them columnwise to US adress table
    cusip6 = [firstx(x, 6) for x in adr_US['cusip']]
    cusip8 = [firstx(x, 8) for x in adr_US['cusip']]
    adr_US['cusip6'] = cusip6
    adr_US['cusip8'] = cusip8
    adr_US[['cusip6', 'cusip8', 'conm', 'fic', 'city']].to_csv(
        'adr_US_c.csv', index=False)

# load clean adresses
adr_c = pd.read_csv('adr_c.csv')
adr_US_c = pd.read_csv('adr_US_c.csv')

# add smi adresses
adr_c = adr_c.append(smi_adr)

# merge stock exchanges with cities to get coordinates.
SEs_geo = SEs.merge(cities, how='left', left_on=['city', 'iso3'], right_on=[
                    'city_ascii', 'iso3']).iloc[:, [0, 2, 4, 5, 6, 7]]

# get country codes
cc = [firstx(x, 2) for x in sec['isin'].values]
sec['country_code'] = cc
sec['country_code'][-sec['country_code'].isin(country_codes)] = 'invalid'
SEs_geo.head()

# *** find matching ISIN for Options *** #


pre_calc = True
# isolate Options
opt = sec[sec['gr_details'] == 'Options']
# define a function to separate the first term of the symbol


def cut(x):
    return x.split(' ', 1)[0]


# get a list with all symbols (first part)
symbols_opt = [cut(x) for x in opt['name'].values]
cc_opt = opt['country_code'].values
tup_opt = list(zip(symbols_opt, cc_opt))
if not pre_calc:
    # collect a dictionary with: key=symbol, value=isin. Map symbol to isin if unambiguous. Take advantage of redundant symbols.
    coll = dict()
    for i in tqdm(set(tup_opt)):
        if i[0] in coll:
            if coll[i[0]] == 'ambiguous':
                # select subpart of securities with given symbol
                sub = sec[sec['symbol'] == i[0]]
                sub_cc = sub[sub['country_code'] == i[1]]
                # check if only one ISIN is present
                if len(sub['isin'].unique()) == 1:
                    coll[i[0]] = sub['isin'].unique()[0]
                elif i[1] != 'invalid' and len(sub['isin'].unique()) > 1 and len(sub_cc['isin'].unique()) == 1:
                    coll[i[0]] = sub_cc['isin'].unique()[0]
                else:
                    coll[i[0]] = 'ambiguous'
        else:
            # select subpart of securities with given symbol
            sub = sec[sec['symbol'] == i[0]]
            sub_cc = sub[sub['country_code'] == i[1]]
            # check if only one ISIN is present
            if len(sub['isin'].unique()) == 1:
                coll[i[0]] = sub['isin'].unique()[0]
            elif i[1] != 'invalid' and len(sub['isin'].unique()) > 1 and len(sub_cc['isin'].unique()) == 1:
                coll[i[0]] = sub_cc['isin'].unique()[0]
            else:
                coll[i[0]] = 'ambiguous'
    pickle.dump(coll, open('isin_ambig_dict.p', 'wb'))

    # *** find matching ISIN for Derivatives *** #


pre_calc = True
# isolate Derivatives
der = sec[sec['gr_details'] == 'Derivatives']
# get a list with all symbols (first part)
symbols_der = [cut(x) for x in der['name'].values]
cc_der = der['country_code'].values
tup_der = list(zip(symbols_der, cc_der))
if not pre_calc:
    # collect a dictionary with: key=symbol, value=isin. Map symbol to isin if unambiguous. Take advantage of redundant symbols.
    coll = dict()
    for i in tqdm(set(tup_der)):
        # only consider symbols which have fewer than 5 characters
        if len(i[0]) < 5:
            if i[0] in coll:
                if coll[i[0]] == 'ambiguous':
                    # select subpart of securities with given symbol
                    sub = sec[sec['symbol'] == i[0]]
                    sub_cc = sub[sub['country_code'] == i[1]]
                    # check if only one ISIN is present
                    if len(sub['isin'].unique()) == 1:
                        coll[i[0]] = sub['isin'].unique()[0]
                    elif i[1] != 'invalid' and len(sub['isin'].unique()) > 1 and len(sub_cc['isin'].unique()) == 1:
                        coll[i[0]] = sub_cc['isin'].unique()[0]
                    else:
                        coll[i[0]] = 'ambiguous'
            else:
                # select subpart of securities with given symbol
                sub = sec[sec['symbol'] == i]
                sub_cc = sub[sub['country_code'] == i[1]]
                # check if only one ISIN is present
                if len(sub['isin'].unique()) == 1:
                    coll[i[0]] = sub['isin'].unique()[0]
                elif i[1] != 'invalid' and len(sub['isin'].unique()) > 1 and len(sub_cc['isin'].unique()) == 1:
                    coll[i[0]] = sub_cc['isin'].unique()[0]
                else:
                    coll[i[0]] = 'ambiguous'
        else:
            coll[i[0]] = 'unknown'
    pickle.dump(coll, open('isin_ambig_dict_der.p', 'wb'))

# load the precalculated object
coll_opt = pickle.load(open('isin_ambig_dict.p', 'rb'))
coll_der = pickle.load(open('isin_ambig_dict_der.p', 'rb'))

warnings.filterwarnings("ignore")
# map new ISINs to Option securities. Do the same for CUSIP. When ISIN is ambiguous then so is the CUSIP.
isins = []
for s in tqdm(range(len(symbols_opt))):
    symbol = symbols_opt[s]
    isins.append(coll_opt[symbol])
opt['isin'] = isins
#opt['cusip'] = [extract_cusip6(x) for x in isins]
# simplify the name by replacing it with the symbol
opt['name'] = symbols_opt
# replace in securities table
sec[sec['gr_details'] == 'Options'] = opt

isins = []
for s in tqdm(range(len(symbols_der))):
    symbol = symbols_der[s]
    isins.append(coll_der[symbol])
der['isin'] = isins
#der['cusip'] = [extract_cusip6(x) for x in isins]
# simplify the name by replacing it with the symbol
der['name'] = symbols_der
# replace in securities table
sec[sec['gr_details'] == 'Derivatives'] = der
print(sec.head(20))

del opt, tup_opt, cc_opt, symbols_opt, der, tup_der, cc_der, symbols_der, isins

# extract the country code and the 6-digit-CUSIP from the ISIN of the securities


def extract_cusip6(x):
    if firstx(x, 2) in ['US', 'CA']:
        return x[2:8]
    else:
        return 'NoCUSIP'


def extract_cusip8(x):
    if firstx(x, 2) in ['US', 'CA']:
        return x[2:10]
    else:
        return 'NoCUSIP'


cusip6 = [extract_cusip6(x) for x in sec['isin']]
cusip8 = [extract_cusip8(x) for x in sec['isin']]
sec['cusip6'] = cusip6
sec['cusip8'] = cusip8
print(sec.head(20))


# merge the adress dataframe with the cities dataframe to combine ISIN/CUSIP with longitude and latitude
# Results in two merged tables once for CUSIP and once for ISIN.
m = adr_c.merge(cities, left_on=['city', 'fic'], right_on=[
                'city_ascii', 'iso3'], how='inner')[['conm', 'isin', 'iso3', 'lat', 'lng', 'city_x']]
m_US = adr_US_c.merge(cities, left_on=['city', 'fic'], right_on=['city_ascii', 'iso3'], how='inner')[
    ['conm', 'cusip6', 'cusip8', 'iso3', 'lat', 'lng', 'city_x']]


# take the mean of lat, lng for ISINs/CUSIPs with multiple coordinate information (possible data contamination)
counts = m['isin'].value_counts()
for i in tqdm(range(len(counts))):
    if counts.values[i] > 1:
        sub = m[m['isin'] == counts.index[i]]
        mean_lat = sub['lat'].mean()
        mean_lng = sub['lng'].mean()
        sub.iloc[0, 4] = mean_lat
        sub.iloc[0, 5] = mean_lng
        # drop multiple
        m.drop(m[m['isin'] == counts.index[i]].index, inplace=True)
        # replace by mean
        m = m.append(sub.iloc[0, :])

m_US_cusip8 = m_US.copy()
counts = m_US_cusip8['cusip8'].value_counts()
for i in tqdm(range(len(counts))):
    if counts.values[i] > 1:
        sub = m_US_cusip8[m_US_cusip8['cusip8'] == counts.index[i]]
        mean_lat = sub['lat'].mean()
        mean_lng = sub['lng'].mean()
        sub.iloc[0, 4] = mean_lat
        sub.iloc[0, 5] = mean_lng
        # drop multiple
        m_US_cusip8.drop(
            m_US_cusip8[m_US_cusip8['cusip8'] == counts.index[i]].index, inplace=True)
        # replace by mean
        m_US_cusip8 = m_US_cusip8.append(sub.iloc[0, :])

m_US_cusip6 = m_US.copy()
counts = m_US_cusip6['cusip6'].value_counts()
for i in tqdm(range(len(counts))):
    if counts.values[i] > 1:
        sub = m_US_cusip6[m_US_cusip6['cusip6'] == counts.index[i]]
        mean_lat = sub['lat'].mean()
        mean_lng = sub['lng'].mean()
        sub.iloc[0, 4] = mean_lat
        sub.iloc[0, 5] = mean_lng
        # drop multiple
        m_US_cusip6.drop(
            m_US_cusip6[m_US_cusip6['cusip6'] == counts.index[i]].index, inplace=True)
        # replace by mean
        m_US_cusip6 = m_US_cusip6.append(sub.iloc[0, :])

print(m.head())

print('------------------------start problem zone')
print(sec.head())

chunksize = 50000
rows = len(sec.index)
for chunk in range(0, math.ceil(rows/chunksize)):
    sec_chunk = sec.iloc[chunk*chunksize:(chunk*chunksize +
                                          chunksize)]
    # merge the securities with the geographic information. Here again once for ISIN/CUSIP
    sec_geo = sec_chunk.merge(m, how='left', on=['isin'])
    # .iloc[:,np.r_[0:12,14:18]].rename(columns={'cusip6_x':'cusip6', 'city_x':'city'})
    sec_geo_cusip8 = sec_chunk.merge(m_US_cusip8, how='left', on=['cusip8'])

    sec_geo_cusip6 = sec_chunk.merge(m_US_cusip6, how='left', on=['cusip6'])

    sec_geo_cusip8[np.logical_xor((-sec_geo_cusip8['city_x'].isnull()).to_numpy(), (-sec_geo_cusip6['city_x'].isnull()).to_numpy())
                   ] = sec_geo_cusip6[np.logical_xor((-sec_geo_cusip8['city_x'].isnull()).to_numpy(), (-sec_geo_cusip6['city_x'].isnull()).to_numpy())]

    # replace those rows where the city value for the CUSIP-merge is NOT null with the values from the CUSIP merge
    sec_geo.loc[-sec_geo_cusip8['city_x'].isnull()
                ] = sec_geo_cusip8.loc[-sec_geo_cusip8['city_x'].isnull()]

    SE_main_loc = pd.read_csv('stock_main_loc.csv', header=None, names=[
        'country_code', 'city'])

    # for shares and bonds where no match occured until now, look for main stock exchange in of country code
    bonds_shares_no_match = (sec_geo[(sec_geo['gr'].isin(('Shares', 'Bonds'))) & (sec_geo['city_x'].isnull())].merge(
        SE_main_loc, how='left', on=['country_code']))[['security_id', 'isin', 'currency', 'stock', 'symbol', 'name', 'cfi', 'gr',
                                                       'gr_details', 'country_code', 'cusip6', 'cusip8', 'city']]  # .iloc[:, [*range(0, 11), 16]]

    # merge stock market main location with the cities datatable

    def copyrow(df, row_idx, col_idx, master):
        df_copy = df.copy()
        m_row = df_copy.iloc[master, col_idx]
        df_copy.iloc[row_idx, col_idx] = m_row

        return df_copy

    SE_main_loc_geo = SE_main_loc.merge(cities, how='left', left_on=['city', 'country_code'], right_on=[
                                        'city_ascii', 'iso2'])[['country_code', 'iso2', 'iso3', 'lat', 'lng', 'city_x']]
    SE_main_loc_geo = copyrow(SE_main_loc_geo, [3, 20, 29], [
        1, 2, 3, 4], master=28)
    SE_main_loc_geo = copyrow(SE_main_loc_geo, [15], [
        1, 2, 3, 4], master=13).drop('iso2', axis=1)

    bonds_shares_SE_main = bonds_shares_no_match.merge(SE_main_loc_geo, how='left', left_on=[
        'city', 'country_code'], right_on=['city_x', 'country_code'])

    sec_geo[(sec_geo['gr'].isin(('Shares', 'Bonds'))) & (
        sec_geo['city_x'].isnull())] = bonds_shares_SE_main.values

    # Due to several problems with the data some symbols will be filled in manually

    # NY
    NY = sec_geo[sec_geo['name'].isin(
        ('EMINI', 'Emini', 'SPY', 'QQQ', 'MNQ', 'DJIA', '.DJIA', 'NDX', 'IWM', 'DIA', 'SPX', 'TQQQ', 'C'))]
    NY['iso3'] = 'USA'
    NY['lat'] = cities[cities['city_ascii'] == 'New York']['lat'].values[0]
    NY['lng'] = cities[cities['city_ascii'] == 'New York']['lng'].values[0]
    NY['city_x'] = cities[cities['city_ascii'] == 'New York']['city'].values[0]
    sec_geo[sec_geo['name'].isin(('EMINI', 'Emini', 'SPY', 'QQQ', 'MNQ',
                                  'DJIA', '.DJIA', 'NDX', 'IWM', 'DIA', 'SPX', 'TQQQ', 'C'))] = NY

    # MVIEW
    MVIEW = sec_geo[sec_geo['name'].isin(('GOOG', 'GOOGL'))]
    MVIEW['iso3'] = 'USA'
    MVIEW['lat'] = cities[cities['city_ascii']
                          == 'Mountain View']['lat'].values[0]
    MVIEW['lng'] = cities[cities['city_ascii']
                          == 'Mountain View']['lng'].values[0]
    MVIEW['city_x'] = cities[cities['city_ascii']
                             == 'Mountain View']['city'].values[0]
    sec_geo[sec_geo['name'].isin(('GOOG', 'GOOGL'))] = MVIEW

    # FRANKFURT
    FRANKFURT = sec_geo[sec_geo['name'].isin(('DAX', 'ODAX', 'SX5E'))]
    FRANKFURT['iso3'] = 'DEU'
    FRANKFURT['lat'] = cities[cities['city_ascii']
                              == 'Frankfurt']['lat'].values[0]
    FRANKFURT['lng'] = cities[cities['city_ascii']
                              == 'Frankfurt']['lng'].values[0]
    FRANKFURT['city_x'] = cities[cities['city_ascii']
                                 == 'Frankfurt']['city'].values[0]
    sec_geo[sec_geo['name'].isin(('DAX', 'ODAX', 'SX5E'))] = FRANKFURT

    # ZURICH
    ZURICH = sec_geo[sec_geo['name'].isin(('SMI', 'OSMI', 'CSGN', 'BAEN'))]
    ZURICH['iso3'] = 'CHE'
    ZURICH['lat'] = cities[cities['city_ascii'] == 'Zurich']['lat'].values[0]
    ZURICH['lng'] = cities[cities['city_ascii'] == 'Zurich']['lng'].values[0]
    ZURICH['city_x'] = cities[cities['city_ascii']
                              == 'Zurich']['city'].values[0]
    sec_geo[sec_geo['name'].isin(('SMI', 'OSMI', 'CSGN', 'BAEN'))] = ZURICH

    # VEVEY
    VEVEY = sec_geo[sec_geo['name'].isin(('NESN', 'NESTLE'))]
    VEVEY['iso3'] = 'CHE'
    VEVEY['lat'] = cities[cities['city_ascii'] == 'Vevey']['lat'].values[0]
    VEVEY['lng'] = cities[cities['city_ascii'] == 'Vevey']['lng'].values[0]
    VEVEY['city_x'] = cities[cities['city_ascii'] == 'Vevey']['city'].values[0]
    sec_geo[sec_geo['name'].isin(('NESN', 'NESTLE'))] = VEVEY

    # GENEVA
    GENEVA = sec_geo[sec_geo['name'].isin(('GIVN', 'GIVAUDAN'))]
    GENEVA['iso3'] = 'CHE'
    GENEVA['lat'] = cities[cities['city_ascii'] == 'Geneva']['lat'].values[0]
    GENEVA['lng'] = cities[cities['city_ascii'] == 'Geneva']['lng'].values[0]
    GENEVA['city_x'] = cities[cities['city_ascii']
                              == 'Geneva']['city'].values[0]
    sec_geo[sec_geo['name'].isin(('GIVN', 'GIVAUDAN'))] = GENEVA

    # LONDON
    LONDON = sec_geo[sec_geo['name'].isin(('VXX', 'UVXY', 'XAG-USD'))]
    LONDON['iso3'] = 'GBR'
    LONDON['lat'] = cities[cities['city_ascii'] == 'London']['lat'].values[0]
    LONDON['lng'] = cities[cities['city_ascii'] == 'London']['lng'].values[0]
    LONDON['city_x'] = cities[cities['city_ascii']
                              == 'London']['city'].values[0]
    sec_geo[sec_geo['name'].isin(('VXX', 'UVXY', 'XAG-USD'))] = LONDON

    # parallel to fill all the remaining NaN-values a separate table is produced where the securities are merged based on stock exchange location.
    sec_SE = sec_chunk.merge(
        SEs_geo, how='left', left_on='stock', right_on='SE')

    # as a last step fill in the coordinates of the missing securites with coordinates of their stock exchange
    # copy previous dataframe
    sec_geo_se = sec_geo
    # mask to fill in remaining values
    mask = sec_geo['lat'].isnull()
    # columnwise fill lat/lng with values from stock exchange locations
    sec_geo_se['lat'].loc[mask] = sec_SE['lat'].loc[mask]
    sec_geo_se['lng'].loc[mask] = sec_SE['lng'].loc[mask]
    sec_geo_se['city_x'].loc[mask] = sec_SE['city_ascii'].loc[mask]

    if os.path.isfile('data/distance.csv'):
        sec_geo_se[['security_id', 'isin', 'stock', 'name', 'gr', 'gr_details',
                    'cusip6', 'cusip8', 'city_x', 'iso3', 'lat', 'lng']].to_csv('distance.csv', header=['security_id', 'isin', 'stock', 'name', 'gr', 'gr_details',
                                                                                                        'cusip6', 'cusip8', 'city_x', 'iso3', 'lat', 'lng'], index=False)
    else:
        sec_geo_se[['security_id', 'isin', 'stock', 'name', 'gr', 'gr_details',
                    'cusip6', 'cusip8', 'city_x', 'iso3', 'lat', 'lng']].to_csv('distance.csv', mode='a', header=['security_id', 'isin', 'stock', 'name', 'gr', 'gr_details',
                                                                                                                  'cusip6', 'cusip8', 'city_x', 'iso3', 'lat', 'lng'], index=False)

    print('chunk ', chunk, 'done.')
