# -*- coding: utf-8 -*-
"""
Created on Sun Jan  1 14:50:07 2017

@author: lparker
"""

import pandas as pd
import scipy as sp
import numpy as np
#from itertools import compress
import matplotlib.pyplot as plt
#import matplotlib as mpl

##Attempt to read in and visualize MAB data
#dataFileIn = './pScheduleCalcBernData_trial.txt'
##Datafile after modifications to consolidate output
#data_file_in = 'pScheduleCalcBern_2017_07_11__12_34_34.txt'
data_file_in = 'pScheduleCalcBern_ucb_2017_07_25__13_10_09.txt'
#colT = ['id', 'selx', 'sely', 'rngP', 'rng', 'out', 'bern_cnt', 'distribution', 'soc', 'loc_cnt',
#        'iter', 'sol_type', 'dist_tot']  # Define the column headers for data extraction
ri = pd.read_table(data_file_in, header=None, index_col=False,names=['indata'])
##Slice content to 1) discard "<YYYY_MM_DD__HH_MM_SS> ~ <INFO> :" timestamp
##and 2) re-index
#ri = ri.loc[1::2,:].reset_index(drop=True)
##Parse header information

"""
STEP 0
Based on the format of the moos-ivp-nuwc pScheduleCalc log file, extract first 
num_loc * 2 lines (i.e., if the number of candidate locations is 20, then
extract the first 40 lines, excluding headers)
"""
num_loc = 20
candidate_a_pos = pd.DataFrame(ri.loc[2:(num_loc+1),'indata'].str.split().tolist())
#agent_a_pos = pd.DataFrame(agent_a_pos[3].str.split(',').tolist()).astype(float) 
candidate_a_pos = np.array(candidate_a_pos[3].str.split(',').tolist()).astype(float) 
        
candidate_b_pos = pd.DataFrame(ri.loc[(num_loc+4):(2*num_loc+3),'indata'].str.split().tolist())   
#agent_b_pos = pd.DataFrame(agent_b_pos[3].str.split(',').tolist()).astype(float)
candidate_b_pos = np.array(candidate_b_pos[3].str.split(',').tolist()).astype(float) 

"""
STEP 1
Extract indices of each location where candidate locations are evaluated.
Using soln_id, extract all instances of where candidate locations are evaluated
and store in dataframe. Create an array of the length of the boolean vector,
ref_id, resulting from locating all instances of where Gittins Index is evaluated.
#Reference: https://stackoverflow.com/questions/18665873/filtering-a-list-based-on-a-list-of-booleans
"""
soln_id = ri['indata'].str.contains('\CBVec')
soln_id = soln_id[soln_id].index.tolist()

'''
#Alternative implementation. For loop only necessary when scrolling across
#multiple columns
for col in ri: soln_id = ri[col].str.contains('\GittinsVec')
ref_id = np.arange(0,len(ri))
soln_id = list(compress(ref_id, soln_id))
'''
"""
STEP 2
Extract and store each instance of candidate locations being evaluated (id, 
std_dev, std_dev_avg, num_pulls, etc) and store as a dict of dataframes
"""
eval_set = {}
for s in soln_id:

    #Slice using .loc, includes the last specified row
    eval_frame = pd.DataFrame(ri.loc[s+1:s+num_loc,'indata'].str.split().tolist())
    #Alternative decomposition, use .iloc, includes up to, but not including the last specified row
    #eval_frame = pd.DataFrame(ri.iloc[s+1:s+1+num_loc].indata.str.split().tolist())    
    eval_frame = eval_frame[[2, 6, 10, 16, 20]].astype(float)
    eval_frame.columns = ['id', 'conf', 'theta_avg', 'num_pull', 'ucb']

    '''Create a dictionary of dataframes to store each instance where solution 
    is called and may be referenced by the position in the series of data
    '''
    eval_set[s+1] = eval_frame   
    
"""
STEP 
Extract timeseries of Vehicle A loction, enable the plotting of how the position
to the estimation loction of the TX vehicle is changing. As with searching for
the canidate locations, also extract the reported vehicle locations.
"""
#Search for ids where vehicle positon changes
veh_id = ri['indata'].str.contains('\Vehicle A Position')
veh_id = veh_id[veh_id].index.tolist()
#Sort through veh_id to identify discontinuities where vehicle navigation
#pauses to make intelligent decision and evaluate solution for candiate locations
nav_pos = np.array([veh_id[0]]) #Presume the first index contains a valid value

for e in np.arange(1,len(veh_id)):
    if (veh_id[e] - veh_id[e-1]) > 1:
        nav_pos = np.append(nav_pos,veh_id[e])

'''
HERE I'M TRYING TO EXTRACT AND PARSE ALL THE LINES THAT START WITH 'VEHICLE A'
TO GET THEIR POSITIONS AND SEPARATION DISTANCE, BUT ALSO INCLUDE A FLAG WHEN THERE
HAS BEEN A PAUSE/INTERRUPT TO EVALUATE THE INTELLIGENCE FUNCTION AND SPIT OUT THE STATE
OF EACH 'ARM', I.E., THE LINES THAT START WITH 'ID = '. I WANTED TO CREATE AN 
EMPTY DATAFRAME FIRST, DEFINING THE COLUMNS, AND THEN JUST EXTRACT EACH LINE, CREATE
AN ARRAY, AND APPEND IT TO THAT DATAFRAME'
'''
#Use nav_pos to cycle through indices and collect vehicle positions UNTIL a break
#in the sequence, store each set and calculate total distance travelled.
agent_a_pos = pd.DataFrame(columns=['xpos', 'ypos', 'sep_dist', 'mark'])

for n in nav_pos:
    k = ri.loc[[n],'indata'].str.contains('\Vehicle A Position')
    print(n)
    up_cnt = 0
    #Mark first datapoint
    agent_a_pos.append(pd.DataFrame([[0,0,0,1]]),ignore_index=True)
    while (k.bool == True):
        agent_a_split = pd.DataFrame(ri.loc[[n+up_cnt],'indata'].str.split().tolist())
        a = agent_a_split[4].str.split(',').tolist()
        a = a[0]
        a = list(map(float, a))
        print("n: ", n, "up_cnt", up_cnt)
        #Generate a row state vector for Vehicle A 
        #append_array = pd.DataFrame([[float(a[0]), float(a[1]), float(agent_a_split[8]), int(0)]])
        append_array = {'xpos':float(a[0]), 'ypos':float(a[0]), 'sep_dist':float(agent_a_split[8]), 'mark':int(0)}
        agent_a_pos.append(append_array,ignore_index=True)
        up_cnt += 1
        k = ri.loc[[n+up_cnt],'indata'].str.contains('\Vehicle A Position')
        
    #Extract Vehicle A position        
        #Use DataFrame instead of numpy array
     #   
        
#Next steps: Store each matrix into an array.
#rim = pd.DataFrame(ri['indata'].str.split().tolist())#columns=['ta1','date','time','ta2','ta3','label','value'])
##Shift top row to align values
#rim.iloc[0] = rim.iloc[0].shift(-1)
#Remove extraneous columns (e.g., "=" and "|")
#col_to_keep = [3,7,11,15,19,23] 
#rim = rim[col_to_keep].astype(float)
#rim.columns=['id','posx','posy','success','n','separation']
#nav_sel = rim.loc[:,['posx','posy']]
#plt.figure(1)
#plt.scatter(nav_sel['posx'], nav_sel['posy'])


#Collect initial information from 0-th row
#rim = rim[0].shift(-1)
#init_data = pd.DataFrame([[rim.loc[0,4],rim.loc[0,8],rim.loc[0,12],rim.loc[0,16]]], columns = ['id','posx','posy','success'])

#new_data = columns = ['id','posx','posy','success'])

#print(data_in.dtypes) #Print datatype


#data = pd.read_csv("./pScheduleCalcBernData", header=None,names=['id','selx','sely','rng','out'])
#locs = pd.read_csv("./testloc_100_100_2_rndgamma.csv", header=None, names=['alocx','alocy','blocx','blocy'])

#N=len(locs) #Number of locations visited
#tot = len(data) #Number of trials
#data[['selx','sely']] = data[['selx','sely']].astype(float)
#data[['id','out']] = data[['id','out']].astype(int)

#Indices are 1-based since being pulled from MATLAB
'''
#Generate a new DataFrame containing the candidate locations and statistics of each
#candLoc = locs.loc[:,['alocx','alocy']]

#Concatenate candidate locations from 'locs' and their associated output(success and failures)
candLoc = locs.loc[:,['alocx','alocy']]
candLoc = pd.concat([(locs.loc[:,['alocx','alocy']]), pd.DataFrame({'out':[]}).astype(object), pd.DataFrame({'trials':[]}).astype(object), pd.DataFrame({'success':[]}).astype(object)], axis=1)

#candLoc.loc[[1],['out']] = np.array(data.loc[(data['id'] == 1),'out'])
tally = 0
for r in np.arange(0,N):
    candLoc.set_value(r, 'out', np.array(data.loc[data['id'] == (r+1),'out']))
    candLoc.set_value(r, 'trials', len(np.array(data.loc[data['id'] == (r+1),'out'])))
    candLoc.set_value(r, 'success', sum(np.array(data.loc[data['id'] == (r+1),'out'])))    
    #tally = tally + len(np.array(data.loc[data['id'] == (r+1),'out']))

#Histogram of frequency of visited locations
hdata = np.histogram(data['id'],bins=N)
hdata = hdata[0]
#bdata = np.arange(0,)

plt.close('all')

# Just a figure and one subplot
f, (ax1, ax2) = plt.subplots(2, 1)
#font = {'family' : 'normal',
#        'weight' : 'bold',
#        'size'   : 10}
#Set up 2x1 plots for visualization
NN = 2
params = plt.gcf()
pltSize = params.get_size_inches()
params.set_size_inches( (pltSize[0]*NN, pltSize[1]*NN) )
#mpl.rc('font', **font)
mpl.rc('xtick', labelsize=10)
mpl.rc('ytick', labelsize=10) 

#Remove the extra space around the plot
plt.subplots_adjust(hspace=0.4)
#Plot LHS plot reflecting success and failures across locations
ind = np.arange(1,N+1)    # The x-axis for the locations considered
width = 0.35 #Width of bar plot
good = candLoc.loc[:,'success'].astype(int)
bad = candLoc.loc[:,'trials'].astype(int) - candLoc.loc[:,'success'].astype(int)
p1 = ax1.bar(ind, bad, width, color='r', align='center')
p2 = ax1.bar(ind, good, width, color='b', align='center')
ax1.set_xlabel('Candidate Receive Locations', multialignment='center', fontsize=14)
ax1.set_ylabel('Transmissions', multialignment='center', fontsize=14)
ax1.set_title('Projected Acomms Success/Failures', fontsize=14, fontweight='bold')
ax1.set_xticks(ind)
ax1.set_yticks(np.arange(0, 12, 2))
ax1.legend((p1[0], p2[0]), ('Failure', 'Success'))

#Plot RHS plot reflecting spatial distribution of trials across locations
colors = candLoc['success']/tot #Scale by 
#plt.scatter(locs['alocx'], locs['alocy'], s=tot*hdata, c=colors, alpha=0.5)
ax2.scatter(locs['alocx'], locs['alocy'], s=tot*hdata, alpha=0.5)
ax2.set_xlabel('Easting [m]', fontsize=14)
ax2.set_ylabel('Northing [m]', fontsize=14)
ax2.set_title('Spatial Distribution of Visits to Candidate Locations', fontsize=14, fontweight='bold')
ax2.set_xlim(min(locs['alocx'])-2, max(locs['alocx'])+1)
#plt.colorbar()
#plt.clim(0,1)

f.savefig('test.png', bbox_inches='tight')  
f.show()

print("%% Success: %6.2f \n"% (100*candLoc.loc[:,'success'].astype(int).sum(axis=0)/tot))
#plt.show()
'''