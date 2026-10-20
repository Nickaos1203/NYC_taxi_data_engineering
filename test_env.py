from dotenv import load_dotenv
import os

load_dotenv()

print("ACCOUNT:", bool(os.getenv("SNOWFLAKE_ACCOUNT")))
print("USER:", bool(os.getenv("SNOWFLAKE_USER")))
print("PASSWORD:", bool(os.getenv("SNOWFLAKE_PASSWORD")))