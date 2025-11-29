"""This module provides a function to connect to the PostgreSQL database."""
import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

def get_db_connection():
    """Establishes a connection to the PostgreSQL database.

    Returns:
        psycopg2.extensions.connection: A connection object to the database.
    """
    conn = psycopg2.connect(os.getenv("DB_DSN"))
    return conn
