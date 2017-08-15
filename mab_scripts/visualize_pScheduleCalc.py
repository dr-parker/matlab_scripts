from bokeh.plotting import figure, output_file, show, ColumnDataSource

from bokeh.models import HoverTool

# read in data file and populate a list containing the contents of the file

#data_file_in = open('pScheduleCalcBern_ucb_2017_07_25__13_19_09.txt.log', 'r')
#data_file_in = open('pScheduleCalcBern_Gittins_Index_test100.txt','r')
data_file_in = open('GI_100.txt','r')

lst = [line.strip() for line in data_file_in.readlines()] #Remove extra white space from front and back of lines

#Identify the total number of state updates by searching from bottom of file
state_size = []
for line in reversed(lst):
    if 'Current State' in line:
        state_size = int(line[line.index(':') + 2:])
        break

arm_state_list = [dict() for x in range(state_size)]
# initalize empty lists for data

a_waypoint_lat = []

a_waypoint_lon = []

b_waypoint_lat = []

b_waypoint_lon = []

rx_pos = {'a_lat':[],'a_lon': []}
tx_pos = {'a_mean_lat':[],'a_mean_lon': []}

a_lon = []

arm_state = {'id': [], 's1': [], 's2': [], 'num_pull': [], 'index_val': []}

best_arm_state = {'count': [], 'tot_dist': [], 'id': [], 'lat': [], 'lon': [], 'success': []}
state_count = 0
#Define parameters
N = 9

# initialize dictionary to be used for hover data
'''
state_vec = {'id': [], 's1': [], 's2': [], 'num_pull': [], 'index_val': []}
rx_pos = {}
d1 = {i: [] for i in range(N)}

data.update(d1)
'''
# iterate over the list

for line in lst:

    # indication of A waypoints

    if 'Vehicle A Way Points' in line:

        for i in range(1, N+1):

            # slice the line into lat and long based on the position of the = and , in the data. Append to lists.
            nxt_ln = lst.index(line) + i #MDefine the indicie of the next line of interest
            #Treat lst[nxt_ln] as an object and specify the start and end indices s.t. the index of '=' is 0
            a_waypoint_lat.append(lst[nxt_ln] [lst[nxt_ln].index('=') + 2:lst[nxt_ln].index(',')])

            a_waypoint_lon.append(lst[nxt_ln] [lst[nxt_ln].index(',') + 1:])

            

# commented out to use B waypoint average

        """

        elif 'Vehicle B Way Points' in line:

        for i in range(1, N+1):

            b_waypoint_lat.append(lst[lst.index(line) + i]

                                  [lst[lst.index(line) + i].index('=') + 2:lst[lst.index(line) + i].index(',')])

            b_waypoint_lon.append(lst[lst.index(line) + i]

                                  [lst[lst.index(line) + i].index(',') + 1:])

        """

    

    # indication of B mean position

    elif 'Vehicle B Mean Position' in line:

        # slice the line into lat and lon based on the position of the = and , in the data. Append to lists.

        tx_pos['b_mean_lat'].append(float(line[line.index('=') + 3:line.index(',')]))

        tx_pos['b_mean_lon'].append(float(line[line.index(',') + 1:]))

    

    # indication of Vehicle A Position data

    elif 'Vehicle A Position' in line:

        # slice the line into lat and lon based on the position of the =, ,, and |. Append to lists.

        rx_pos['a_lat'].append(float(line[line.index('=') + 3:line.index(',')]))

        rx_pos['a_lon'].append(float(line[line.index(',') + 1:line.index('|') - 1]))

    # identify and format intelligence data for plotting

    elif 'Current State' in line:
        #Retrieve current count of how many times algorithm has been run to identify a solution
        nxt_ln = lst.index(line)  #Define the indicie of the next line of interest   
        #Retrieve updated total distance traveled upon arriving at the most recent waypoint              
        best_arm_state['count'].append(line[line.index(':') + 2:])
        best_arm_state['tot_dist'].append(lst[nxt_ln+1][lst[nxt_ln+1].index('=')+2:])
        best_arm_state['id'].append(lst[nxt_ln+3][lst[nxt_ln+3].index('d = ') + 4:lst[nxt_ln+3].index(' | X')])
        best_arm_state['lat'].append(lst[nxt_ln+3][lst[nxt_ln+3].index('| X = ') + 6:lst[nxt_ln+3].index(' | Y')])
        best_arm_state['lon'].append(lst[nxt_ln+3][lst[nxt_ln+3].index('| Y = ') + 6:lst[nxt_ln+3].index(' | S')])
        best_arm_state['success'].append(lst[nxt_ln+3][lst[nxt_ln+3].index('?') + 4:])       
        
        #Update best_state list
                
        #For the remaining sets, iterate over 
        arm_state = {'id': [], 's1': [], 's2': [], 'num_pull': [], 'index_val': []}
        for i in range(5, N+5):

            # slice the line into lat and long based on the position of the = and , in the data. Append to lists.
            nxt_ln = lst.index(line) + i #MDefine the indicie of the next line of interest
            #Treat lst[nxt_ln] as an object and specify the start and end indices s.t. the index of '=' is 0
            arm_state['id'].append(lst[nxt_ln][lst[nxt_ln].index('d =') + 4:lst[nxt_ln].index(' | Sigma')])        
            arm_state['s1'].append(lst[nxt_ln][lst[nxt_ln].index('q =') + 4:lst[nxt_ln].index(' | Theta')])        
            arm_state['s2'].append(lst[nxt_ln][lst[nxt_ln].index('g =') + 4:lst[nxt_ln].index(' | Num')])        
            arm_state['num_pull'].append(lst[nxt_ln][lst[nxt_ln].index('s =') + 4:lst[nxt_ln].index(' | Val')])        
            arm_state['index_val'].append(lst[nxt_ln][lst[nxt_ln].index('e =') + 4:])       
        arm_state_list[state_count] = arm_state
        #Increment the state counter
        state_count += 1

#Generate performance statistics
percent_success = sum([int(i) for i in best_arm_state['success']])/len([int(i) for i in best_arm_state['success']])
total_distance = float(best_arm_state['tot_dist'][-1])
print(percent_success*100)

'''        
    elif 'BestArmLoc To' in line:
        #Retrieve current state
        best_state.append(line[line.index(':') + 2:])
            # slice the line into lat and long based on the position of the = and , in the data. Append to lists.
        nxt_ln = lst.index(line) + i #MDefine the indicie of the next line of interest        


    elif ((line == 'GittinsVec') || (line == 'UCBVec')) #|| (line == '') || (line == 'GittinsVec')):


        for i in range(N):

            data[i].append(lst[lst.index(line) + i + 1])

        if not a_lat:

            data['lat'].append(0.0)

        else:

            data['lat'].append(a_lat[-1])

        if not a_lon:

            data['lon'].append(0.0)

        else:

            data['lon'].append(a_lat[-1])

    """

print(data)



# initialize html file for interactive bokeh plot

output_file("line.html")



p = figure(plot_width=800, plot_height=600)



# add a circle renderer with a size, color, and alpha

# Commented out to remove waypoints from plots

# p.circle(a_waypoint_lat, a_waypoint_lon, size=20, color="navy", alpha=0.5)

# p.circle(b_waypoint_lat, b_waypoint_lon, size=20, color="red", alpha=0.5)

p.circle(a_lat, a_lon, size=10, color='black', alpha=0.5)

# show the results

show(p)
'''