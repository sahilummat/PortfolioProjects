#!/usr/bin/env python
# coding: utf-8

# In[4]:


#!pip install kaggle
#import kaggle
#!kaggle datasets download ankitbansal06/retail-orders -f orders.csv


# In[5]:


#extract file from zip file
import zipfile
zip_ref = zipfile.ZipFile('orders.csv.zip') 
zip_ref.extractall() # extract file to dir
zip_ref.close() # close file


# In[47]:


##read data from the file and handle null values

pd.set_option('display.max_rows', 500)
#import pandas  as pd
#df= pd.read_csv('orders.csv',na_values=['Not Available', 'unknown'])
#df.head()


# In[14]:


df['Ship Mode'].unique()


# In[24]:


#rename columns names ..make them lower case and replace space with underscore
#df.columns=df.columns.str.lower()
#df.columns=df.columns.str.replace(' ','_')
df.head()


# In[40]:


#derive new columns discount , sale price and profit
#df['discount']=df['list_price']*df['discount_percent']*.01
#df['sale_price']=df['list_price']-df['discount']
df['profit']=df['sale_price']-df['cost_price']
df.head()


# In[44]:


#convert order date from object data type to datetime
#df.dtypes
df['order_date']=pd.to_datetime(df['order_date'],format="%Y-%m-%d")


# In[49]:


#drop cost price list price and discount percent columns
df.drop(columns=['list_price','discount_percent','cost_price'],inplace=True)


# In[50]:





# In[53]:


#load the data into sql server using replace option
import sqlalchemy as sal
engine=sal.create_engine('mssql://DESKTOP-ER88D28\SQLEXPRESS/master?driver=ODBC+DRIVER+17+FOR+SQL+SERVER')
conn=engine.connect()


# In[57]:


#load the data into sql server using append option
df.to_sql('df_orders',con=conn,index=False,if_exists='append')


# In[55]:





# In[ ]:




