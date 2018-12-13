import matplotlib.pyplot as plt
import seaborn as sns
%matplotlib inline 
fig, ax = plt.subplots(figsize=(15,10))
sns.regplot(data=reports, x="days-to-resolve", y='quantity-of-comments')
plt.ylim(0,)