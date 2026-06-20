print("Process Started")
from db_connection import run_query

df=run_query('SELECT count(*) as Total from bank_master')
print('Bank master rows:',df['total'][0])

#All bank list

banks=run_query('SELECT bank_id,bank_name from bank_master GROUP BY bank_id,bank_name ORDER BY 1')
print(banks)

print('Process End')