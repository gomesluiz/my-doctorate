


import matplotlib.pyplot as plt 
import pandas as pd
import seaborn as sns 

# Setup Seaborn
sns.set_context("paper")
sns.set(style="ticks", color_codes=True, font_scale=2)

# Setup Matplotlib
plt.rc('figure', figsize=(20, 20))
plt.style.use('default')
SMALL_SIZE  = 10
MEDIUM_SIZE = 10
BIGGER_SIZE = 12
plt.rc('font',   size=SMALL_SIZE)       # controls default text sizes
plt.rc('axes',   titlesize=SMALL_SIZE)  # fontsize of the axes title
plt.rc('axes',   labelsize=SMALL_SIZE)  # fontsize of the x and y labels
plt.rc('xtick',  labelsize=SMALL_SIZE)  # fontsize of the tick labels
plt.rc('ytick',  labelsize=SMALL_SIZE)  # fontsize of the tick labels
plt.rc('legend', fontsize=SMALL_SIZE)   # legend fontsize
plt.rc('figure', titlesize=SMALL_SIZE)  # fontsize of the figure title
#%matplotlib inline 

# Path of the file to read.
projects = ['eclipse', 'freedesktop', 'gnome', 'mozilla', 'gcc', 'winehq']

# Fixed time threshold.
bug_fix_time_threshold = 365
print("Setup complete")


# ## Step 2. Load data.

# In[3]:


bug_reports_data_list = []
for project in projects:
    bug_reports_path = f"datasets/20190917_{project}_bug_report_data.csv"

    # read bug reports data.
    bug_reports_data = pd.read_csv(bug_reports_path)[0:10000]
    rows_and_cols = bug_reports_data.shape
    print(f"There are {rows_and_cols[0]} rows and {rows_and_cols[1]} columns in {bug_reports_path}.\n")
    print(f"Mean of bug fix time: {bug_reports_data['bug_fix_time'].mean(axis=0)}.\n")
   
    bug_reports_data["project"] = project  
    bug_reports_data_list.append(bug_reports_data) 

# concatenate all bug_reports_data 
bug_reports_all_data = pd.concat(bug_reports_data_list)


# In[4]:


bug_reports_history_data_list = []
for project in projects:
    bug_reports_history_path = f"datasets/20190917_{project}_bug_report_history_data.csv"

    # read bug reports data.
    bug_reports_history_data = pd.read_csv(bug_reports_history_path, sep=',')
 
    # print dataframe information
    rows_and_cols = bug_reports_history_data.shape
    print(f"There are {rows_and_cols[0]} rows and {rows_and_cols[1]} columns in {bug_reports_history_path}.\n")
    
    bug_reports_history_data_list.append(bug_reports_history_data) 

# concatenate all bug_reports_data 
bug_reports_all_history_data = pd.concat(bug_reports_history_data_list)


# ## Step 3. Review the data

# In[5]:


bug_reports_all_data.head()


# In[6]:


bug_reports_all_data.describe()


# In[7]:


bug_reports_all_data.drop(bug_reports_all_data.loc[bug_reports_all_data['bug_fix_time'] < 0].index, inplace=True)
bug_reports_all_data.loc[bug_reports_all_data['bug_fix_time'] < 0]


# In[8]:


bug_reports_all_history_data.head()


# ## Step 4. Pre-processing the data

# In[9]:


bug_reports_all_data['short_description'] = bug_reports_all_data['short_description'].fillna("")
bug_reports_all_data['long_description']  = bug_reports_all_data['long_description'].fillna("")
bug_reports_all_data['short_description_words'] = bug_reports_all_data['short_description'].str.split().apply(lambda l: len(l))
bug_reports_all_data['long_description_words']  = bug_reports_all_data['long_description'].str.split().apply(lambda l: len(l))
bug_reports_all_data['long_lived?']  = bug_reports_all_data['bug_fix_time'].apply(lambda t: 'long-lived' if t > bug_fix_time_threshold else 'short-lived')

bug_reports_all_data.drop(bug_reports_all_data[bug_reports_all_data['severity_category'] == 'not set'].index, inplace=True)
bug_reports_all_data.drop(bug_reports_all_data[bug_reports_all_data['bug_fix_time'] < 0 ].index, inplace=True)

bug_reports_all_data.head()


# In[10]:


bug_reports_all_data['project'].value_counts()


# ### Step 5. How frequent are long-lived bugs?

# In[12]:



for project in projects:
    # group data by project
    counts_by_project  = bug_reports_all_data.loc[bug_reports_all_data['project']==project]['long_lived?'].value_counts()

    # plot pie charts
    sns.set_context("paper")
    sns.set(style="ticks", color_codes=True)
    fig = plt.figure(figsize=(3.5,3.5))
    plt.pie(counts_by_project, autopct='%1.1f%%', labels=counts_by_project.index, colors=['tab:blue', 'tab:red'])
    #plt.title(project.title())
    plt.xlabel('')
    plt.ylabel('')
    plt.savefig(f"figures/rq2-{project}-percentage-of-long-lived-bugs.pdf", format="pdf", dpi=fig.dpi, bbox_inches='tight', pad_inches=0)
    




# In[ ]:




