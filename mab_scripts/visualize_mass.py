"""
Created on Sun Jan  1 14:50:07 2017
@author: lparker
"""
import pandas as pd
import numpy as np
from scipy.spatial.distance import pdist
from scipy.spatial.distance import squareform
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
testloc_rand20.txt
testloc_rand100.txt
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
bC = 3
#bC = (1, 2, 3)       # Number of Bernoulli trials considered (1 - 1of1, 2 - 1of5, 3 - 1of10)

soc = 0  # Type of Success of Communication curve (0 - Gamma, 1 - Exponential)
# soc = (0, 1)

#nIter = 100  #Number of iterations (timesteps or duration, 100, 500, or 1000)
nIters = (50, 75, 100, 125, 150, 175, 200)

#Solution type, (Gittins Index, GI - 0, Upper Confidence Bound, UCB - 1, Epsilon Greedy, EG - 2, Uninformed Random, UR - 2;)
solns = ('GI','UCB','EG','UR')

distrT = 0    # Distribution type (Uniform Random - 0, Mesh grid - 1)
# distrT = (0, 1)

bStationary = 1  # Flag indicating whether or not the TX agent ("B") is stationary (1) or not ()
# bStationary = (0, 1)

N = 20     # Number of candidate locations
# N = (20, 100)

# Import test scenario file
# (e.g., 20 randomly distributed candidate locations: "*_rand20.txt") and

if distrT == 0:  # If Uniformly randomly distributed "arm" locations
    scen = 'rand'  # Define the relevant string
else:
    scen = 'mesh'

#locsFileIn = './testloc_'+scen+str(N)+'_icra.txt'
# Update to match candidate location input file
header_size = np.arange(0,63) # Size of header containing all canidate locations
#Range of seed values used to generate datasets for each set of conditions
sd_rngs = np.arange(143,243)
# Create a list of dictionarys to hold datasets for each seed value
soln_state_list = [dict() for x in range(sd_rngs.size)]
seed_cnt = 0;
#Define dict of solutions
soln_stat = {'GI': [], 'UCB': [], 'EG': [], 'UR': []} #Used for percent successes
soln_dist = {'GI': [], 'UCB': [], 'EG': [], 'UR': []} #Used for total distances
outdir = './outdata_08NOV17/outdata_08NOV17/'
for sd_rngI, sd_rng in enumerate(sd_rngs, start=0):
    dataFileIn = outdir+'improv_aamasdata03NOV17_stationaryB_'+str(bStationary)+'_beta_p95_'+str(sd_rng)+'.txt'
    '''Identify the set of candidate locations within selected datafile associated with the arm specifications
    i.e., rand9 versus rand20 versus mesh9 versus mesh20.'''
    d_file = open(dataFileIn,'r')
    lst = [line.strip() for line in d_file.readlines()] #Remove extra white space from front and back of lines
    for line in lst:
        if (scen+str(N) in line):
            locs =  pd.read_table(dataFileIn,header=None,skiprows=np.arange(lst.index(line)+1),sep=',',names=['alocx', 'alocy', 'blocx', 'blocy'],nrows=N)
            break;
    '''Prepare dataframe containing all data from parameters of interest as it 
    relates to the spatial parameters of the arms'''
    colT = ['id', 'selx', 'sely', 'rngP', 'rng', 'out', 'bern_cnt', 'distribution', 'soc', 'loc_cnt',
            'iter', 'sol_type', 'dist_tot']  # Define the column headers for data extraction
    data_in = pd.read_table(dataFileIn, header=None, skiprows=header_size, sep=',', index_col=False, names=colT)
            
    '''Since data is initially read in as characters, change data types of
    specific columns (i.e., float for some columns and int for others)'''
    data_in[['selx', 'sely', 'rngP', 'rng']] = data_in[['selx', 'sely', 'rngP', 'rng']].astype(float)
    data_in[['id', 'out', 'bern_cnt', 'distribution', 'soc', 'loc_cnt', 'iter', 'sol_type',
            'dist_tot']] = data_in[['id', 'out', 'bern_cnt', 'distribution', 'soc', 'loc_cnt',
                                   'iter', 'sol_type', 'dist_tot']].astype(int)
    
    #Initialize placeholders for data to be stored later
    locs_stat = []
    data_stat = []

    # Printing statistics of different sets of conditions
    for nI, nIter in enumerate(nIters, start=0): #Defines dataset based on the number of decision epochs considered (as of 03NOV17, 50, 100, or 200)
        #print('Iterations: ' + str(nIter))
        for sI, soln in enumerate(solns, start=0): #Specifies the dataset pertaining to a specific solution (GI, UCB, EG, or UR)
            # Define tuple of inputs to parsing function
            test_in = (bC, soc, nIter, distrT, N, sI)
            locs_stat, data_stat = parse_mab_input(data_in, test_in)
            success_total = locs_stat.loc[:, 'success'].astype(int).sum(axis=0)
            trial_total = locs_stat.loc[:, 'trials'].astype(int).sum(axis=0)
#            print(soln)
#            print(nI)
            #Calculate max possible distance that could be traversed by agent
            #in nI decision epochs
            D = nIter*(max(pdist(locs_stat.ix[:,'alocx':'alocy'])))

            if sd_rngI == 0: #Used for initial fill of info
                soln_stat[soln].append([(100*success_total/trial_total)])
                soln_dist[soln].append([data_stat.loc[1, 'dist_tot']/D])
            else:
                soln_stat[soln][nI].append((100*success_total/trial_total)) 
                soln_dist[soln][nI].append(100*(data_stat.loc[1, 'dist_tot']/D))
            #print('%s: %6.2f\t%7.2f\n' % (soln_type[s], (100*success_total/trial_total), data_stat.loc[1, 'dist_tot']))

    #Unused dict of dict
    #soln_state_list[seed_cnt] = soln_stat
    #seed_cnt += 1
soln_mean = {}
soln_mean_dist = {}
    
#soln_mean = {'0':[],'1':[],'2':[],'3':[]}
#soln_mean_dist = {'0':[],'1':[],'2':[],'3':[]}
pretty = ['rp-','bs-','g^-','c*-']
for sI, soln in enumerate(solns, start=0): #Specifies the dataset pertaining to a specific solution (GI, UCB, EG, or UR)
    soln_mean[sI] = [np.mean(soln_stat[soln][0]), np.mean(soln_stat[soln][1]), np.mean(soln_stat[soln][2]), np.mean(soln_stat[soln][3]), np.mean(soln_stat[soln][4]), np.mean(soln_stat[soln][5]), np.mean(soln_stat[soln][6])]
    soln_mean_dist[sI] = [np.mean(soln_dist[soln][0]), np.mean(soln_dist[soln][1]), np.mean(soln_dist[soln][2]), np.mean(soln_dist[soln][3]), np.mean(soln_dist[soln][4]), np.mean(soln_dist[soln][5]), np.mean(soln_dist[soln][6])]
    #soln_std =  [np.std(soln_stat[soln][0]), np.std(soln_stat[soln][1]), np.std(soln_stat[soln][2])]
    #print('Solution: ' + soln + ': ' + str(soln_mean[sI]) + '    Dist: ' + str(soln_mean_dist[sI]))    
#plt.errorbar(nIters,soln_mean,yerr=eg_std)
    
#fig, axs = plt.subplots(nrows=1, ncols=2, sharex=True, figsize=(10, 2))
#ax = axs[0]
#ax.plot(nIters,soln_mean[0],pretty[0],nIters,soln_mean[1],pretty[1],nIters,soln_mean[2],pretty[2],nIters,soln_mean[3],pretty[3])
#ax.legend(['GI','UCB','EG','UR'])
#ax.set_title('Success')
#ax.set_title('Success')
#
#ax = axs[1]
#ax.plot(nIters,soln_mean_dist[0],pretty[0],nIters,soln_mean_dist[1],pretty[1],nIters,soln_mean_dist[2],pretty[2],nIters,soln_mean_dist[3],pretty[3])
#ax.legend(['GI','UCB','EG','UR'])
#ax.set_title('Distance')
for sI, soln in enumerate(solns, start=0): #Specifies the dataset pertaining to a specific solution (GI, UCB, EG, or UR)
    print(solns[sI] + ': '+ str(np.mean(soln_mean[sI])) + ', ' + str(np.mean(soln_mean_dist[sI])))


#fig, axes = plt.subplots(nrows=1, ncols=2)

#plt.setp(axes, xticks=[50, 100, 150, 200], xticklabels=['50', '100', '150', '200'],
        #yticks=[25, 50, 75, 100])
#Use if you want to change one specific set of axes using "set current axes", sca
#plt.sca(axes[0])
#plt.yticks(range(3), ['A', 'Big', 'Cat'])
plt.figure(figsize=(10,4))
plt.subplot(121)
#ax.plot(nIters,soln_mean[0],pretty[0],nIters,soln_mean[1],pretty[1],nIters,soln_mean[2],pretty[2],nIters,soln_mean[3],pretty[3])
#ax.legend(['GI','UCB','EG','UR'])
#ax.set_title('Success')
plt.plot(nIters,soln_mean[0], pretty[0], label="GI")
plt.plot(nIters,soln_mean[1], pretty[1], label="UCB")
plt.plot(nIters,soln_mean[2], pretty[2], label="EG")
plt.plot(nIters,soln_mean[3], pretty[3], label="UR")
plt.xticks([50, 100, 150, 200])
#plt.yticks([25, 50, 75, 100])
#ax.legend(['GI','UCB','EG','UR'])
plt.legend(bbox_to_anchor=(0.1, 1.05, 2., .102), loc=3,
           ncol=4, mode="expand", borderaxespad=0.)
plt.ylabel('% Success')
plt.xlabel('Decision Epoch')
#plt.setp(sp1, xticks=[50, 100, 150, 200], xticklabels=['50', '100', '150', '200'],
#        yticks=[25, 50, 75, 100])
#start, end = plt.Axes.get_xaxis()
#plt.Axes.xaxis.set_ticks(np.arange(0, 200, 25))
#plt.figure(figsize=(10,5))
plt.subplot(122)
#ax.plot(nIters,soln_mean[0],pretty[0],nIters,soln_mean[1],pretty[1],nIters,soln_mean[2],pretty[2],nIters,soln_mean[3],pretty[3])
#ax.legend(['GI','UCB','EG','UR'])
#ax.set_title('Success')
plt.plot(nIters,soln_mean_dist[0], pretty[0], label="GI")
plt.plot(nIters,soln_mean_dist[1], pretty[1], label="UCB")
plt.plot(nIters,soln_mean_dist[2], pretty[2], label="EG")
plt.plot(nIters,soln_mean_dist[3], pretty[3], label="UR")
plt.xticks([50, 100, 150, 200])
plt.xlabel('Decision Epoch')
#plt.yticks([25, 50, 75, 100])
#ax.legend(['GI','UCB','EG','UR'])
#plt.legend(bbox_to_anchor=(0., 1.02, 1., .102), loc=3,
#           ncol=4, mode="expand", borderaxespad=0.)
plt.ylabel('% Distance')

#plt.savefig('rand9exp.png', bbox_inches='tight')


#for index, nI in enumerate(nIter, start=0):
#    print('Index '+ str(index) +' and nI '+ str(nI))
    
'''Prepare data for printing
Figure out how to index a single value from a list of dicts'''
#soln_state_list[:][0] is the same as soln_state_list[0]
#soln_collect = 
#for ss in np.arange(seed_cnt):
#    for st in soln_type:
#      soln_col['st'].append = soln_state_list[ss][st][0]
    
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