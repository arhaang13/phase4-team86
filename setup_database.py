import os
import re
import mysql.connector

DB_CONFIG = {
    "host": "127.0.0.1",
    "user": "root",
    "password": "",
    "database": "flight_tracking"
}

def setup_database():
    try:
        conn = mysql.connector.connect(
            host=DB_CONFIG["host"],
            user=DB_CONFIG["user"],
            password=DB_CONFIG["password"]
        )
        cur = conn.cursor()

        cur.execute(f"CREATE DATABASE IF NOT EXISTS `{DB_CONFIG['database']}`")
        cur.execute(f"USE `{DB_CONFIG['database']}`")

        base_dir = os.path.dirname(__file__)
        
        with open(os.path.join(base_dir, "sql", "schema.sql"), 'r', encoding='utf8') as f:
            schema_sql = f.read()
            
        for result in cur.execute(schema_sql, multi=True):
            if result.with_rows:
                result.fetchall()
        
        with open(os.path.join(base_dir, "sql", "procedures.sql"), 'r', encoding='utf8') as f:
            raw = f.read()
        # remove client side delimiter for mysql connector
        cleaned = re.sub(r'(?mi)^\s*delimiter\b.*$', '', raw)
        parts = cleaned.split('//')

        for part in parts:
            block = part.strip()
            if not block or re.fullmatch(r'(?i)\s*end;?\s*', block):
                continue
                
            if not block.endswith(';'):
                block += ';'
                
            for result in cur.execute(block, multi=True):
                if result.with_rows:
                    result.fetchall()

        conn.commit()
        cur.close()
        conn.close()
        return True

    except Exception as e:
        print(f"Database setup error: {e}")
        return False

if __name__ == "__main__":
    print("Setting up flight_tracking database...")
    if setup_database():
        print("Setup complete.")
    else:
        print("Setup failed.")