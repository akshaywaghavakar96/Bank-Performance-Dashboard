import os
import pandas as pd

from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv()


# Dashboard url
DB_URL =(
          f"postgresql://{os.getenv('DB_USER')}:{os.getenv('DB_PASSWORD')}"
          f"@{os.getenv('DB_HOST')}:{os.getenv('DB_PORT')}/{os.getenv('DB_NAME')}"
)


engine = create_engine(DB_URL)


def run_query(sql : str)    -> pd.DataFrame:
    """Run any sql query and return result as a pandas Dataframe"""
    with engine.connect() as conn:
        return  pd.read_sql(text(sql),conn)