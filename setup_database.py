#!/usr/bin/env python3
import os
import re
import mysql.connector
from mysql.connector import Error

# MySQL configuration
DB_HOST     = "127.0.0.1"
DB_USER     = "root"
DB_PASSWORD = ""
DB_NAME     = "flight_tracking"

def setup_database():
    """
    Creates the database and loads schema, procedures, and views
    without requiring DELIMITER statements.
    """
    try:
        # Connect to MySQL (no special delimiter handling needed)
        conn = mysql.connector.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD
        )
        cur = conn.cursor()

        # Create and select database
        cur.execute(f"CREATE DATABASE IF NOT EXISTS `{DB_NAME}`")
        cur.execute(f"USE `{DB_NAME}`")

        # === 1) Load schema.sql ===
        schema_path = os.path.join(os.path.dirname(__file__), "sql", "schema.sql")
        print(f"→ Loading schema from {schema_path}…")
        schema_sql = open(schema_path, 'r', encoding='utf8').read()
        for result in cur.execute(schema_sql, multi=True):
            if result.with_rows:
                result.fetchall()
        print("✔ schema loaded")

        # === 2) Load procedures and views ===
        proc_path = os.path.join(os.path.dirname(__file__), "sql", "procedures.sql")
        print(f"→ Loading procedures & views from {proc_path}…")
        raw = open(proc_path, 'r', encoding='utf8').read()

        # Remove client-side DELIMITER commands
        cleaned = re.sub(r'(?mi)^\s*delimiter\b.*$', '', raw)
        # Split routines and views on '//' markers
        parts = cleaned.split('//')

        # Execute each routine or view block
        for part in parts:
            block = part.strip()
            if not block:
                continue
            # Skip standalone 'end' fragments
            if re.fullmatch(r'(?i)\s*end;?\s*', block):
                continue
            # Ensure it ends with a semicolon
            if not block.endswith(';'):
                block += ';'
            # Run in multi mode to handle DROP, CREATE, multiple view statements
            for result in cur.execute(block, multi=True):
                if result.with_rows:
                    result.fetchall()

        print("✔ procedures & views loaded")

        conn.commit()
        cur.close()
        conn.close()
        return True

    except Error as e:
        print(f"✖ Database setup error: {e}")
        return False

if __name__ == "__main__":
    print("=== flight_tracking: database setup ===")
    if setup_database():
        print("\nAll done! You can now run your app.")
    else:
        print("\nSetup failed. Check the errors above.")
