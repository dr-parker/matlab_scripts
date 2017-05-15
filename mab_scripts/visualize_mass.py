"""
Created on Sun Jan  1 14:50:07 2017
@author: lparker
"""
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt


def parse_mab_input(data, test):
    # Extract relevant dataset pertaining to test scenario
    # Try to concatenate portions of data_in relevant to the scenario of interest
    data_parse = data.loc[(data['bern_cnt'] == test[0]) & (data['distribution'] == test[3]) &
                          (data['soc'] == test[1]) & (data['loc_cnt'] == test[4]) &
                          (data['iter'] == test[2]) & (data['sol_type'] == test[5]),
                          colT].reset_index(drop=True)

    # Generate new dataframe that stores statistics of each candidate location.
    # Initialize dataframe with candidate locations and append 1) the resulting output vector (variable length)
    # 2) the total number of trials and 3) the number of successes.
    cand_loc = pd.concat([(locs.loc[:, ['alocx', 'alocy']]), pd.DataFrame({'out': []}).astype(object),
                          pd.DataFrame({'trials': []}).astype(object), pd.DataFrame({'success': []}).astype(object)],
                         axis=1)

    for r in np.arange(0, N):
        # Extract the output for all instances of the "r"-th location
        cand_loc.set_value(r, 'out', np.array(data_parse.loc[data_parse['id'] == (r+1), 'out']))

        # Calculate the total length (or trials) associated with the "r"-th location
        cand_loc.set_value(r, 'trials', len(np.array(data_parse.loc[data_parse['id'] == (r+1), 'out'])))

        # Calculate the total number of successes at the "r"-th location
        cand_loc.set_value(r, 'success', sum(np.array(data_parse.loc[data_parse['id'] == (r+1), 'out'])))

    return cand_loc, data_parse

'''
Data Available for analysis (as of 12FEB17)
LOCATION FILES
testloc_rnd20.txt
testloc_rnd100.txt
testloc_mesh20.txt
testloc_mesh100.txt
DATA FILES
testdata12FEB17.txt
'''

# STEP 0: Set up parameters of interest
# Set flag to determine whether you are collecting stats or just plotting examples

# STEP 0.1: If plotFeature == 1, re-define all parameters below as scalars
# (i.e., remove all tuples)
plotFeature = 0  # Set this value to 1

# Initialize parameters
# Define parameters of interest
bC = 1
#bC = (1, 2, 3)       # Number of Bernoulli trials considered (1 - 1of1, 2 - 1of5, 3 - 1of10)

soc = 1  # Type of Success of Communication curve (0 - Gamma, 1 - Exponential)
# soc = (0, 1)

#nIter = 100  #Number of iterations (timesteps or duration, 100, 500, or 1000)
nIter = (100, 500, 1000)

#soln = 0     # Solution of interest (Gittins Index, GI - 0, Uninformed Random, UR - 1; Educated Guess, EG - 2)
soln = (0, 1, 2, 3)

distrT = 1    # Distribution type (Uniform Random - 0, Mesh grid - 1)
# distrT = (0, 1)

bStationary = 1  # Flag indicating whether or not the TX agent ("B") is stationary (1) or not ()
# bStationary = (0, 1)

N = 20       # Number of candidate locations
# N = (20, 100)

# Import test scenario file
# (e.g., 20 randomly distributed candidate locations: "*_rnd20.txt") and

if distrT == 0:  # If Uniformly randomly distributed "arm" locations
    scen = 'rnd'  # Define the relevant string
else:
    scen = 'mesh'

locsFileIn = './testloc_'+scen+str(N)+'_cmp.txt'
locs = pd.read_table(locsFileIn, header=None, sep=',', names=['alocx', 'alocy', 'blocx', 'blocy'])
# Update to match candidate location input file

# Create string for input file
dataFileIn = './improv_testdata15MAY17_stationaryB_'+str(bStationary)+'_beta_p5.txt'
colT = ['id', 'selx', 'sely', 'rngP', 'rng', 'out', 'bern_cnt', 'distribution', 'soc', 'loc_cnt',
        'iter', 'sol_type', 'dist_tot']  # Define the column headers for data extraction
data_in = pd.read_table(dataFileIn, header=None, sep=',', index_col=False, names=colT)

# Change data types of specific columns (i.e., float for some columns and int for others)
data_in[['selx', 'sely', 'rngP', 'rng']] = data_in[['selx', 'sely', 'rngP', 'rng']].astype(float)
data_in[['id', 'out', 'bern_cnt', 'distribution', 'soc', 'loc_cnt', 'iter', 'sol_type',
        'dist_tot']] = data_in[['id', 'out', 'bern_cnt', 'distribution', 'soc', 'loc_cnt',
                               'iter', 'sol_type', 'dist_tot']].astype(int)
locs_stat = []
data_stat = []

# Printing statistics of different sets of conditions
for nI in nIter:
    for s in soln:
        # Define tuple of inputs to parsing function
        test_in = (bC, soc, nI, distrT, N, s)
        locs_stat, data_stat = parse_mab_input(data_in, test_in)
        success_total = locs_stat.loc[:, 'success'].astype(int).sum(axis=0)
        trial_total = locs_stat.loc[:, 'trials'].astype(int).sum(axis=0)
        print("%6.2f\t%7.2f\n" % ((100*success_total/trial_total), data_stat.loc[1, 'dist_tot']))

'''
#Print for a single case
test_in = (bC, soc, nIter, distrT, N, soln)
locs_stat, data_stat = parse_mab_input(data_in, test_in)
success_total = locs_stat.loc[:, 'success'].astype(int).sum(axis=0)
trial_total = locs_stat.loc[:, 'trials'].astype(int).sum(axis=0)
print("%% Success: %6.2f --- Distance: %7.2f\n" % ((100*success_total/trial_total),
                                                           data_stat.loc[1, 'dist_tot']))                                                           
                                                           
print(data_in)
print(data_stat)
toplot = data_stat[['id']].copy()
toplot.reset_index(level=0, inplace=True)

scat = toplot.plot.scatter(x='index', y='id')
scat.set_xlim(0, 2000)
scat.set_ylim(0, 20.5)

line = toplot.plot(x='index', y='id')

plt.show()
'''