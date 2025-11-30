"""This module provides a function to connect to the PostgreSQL database."""
import os
import psycopg2
from psycopg2 import pool
from dotenv import load_dotenv

load_dotenv()

_pool = None

def init_db_pool():
    global _pool
    if _pool is None:
        try:
            # Initialize the connection pool
            _pool = psycopg2.pool.ThreadedConnectionPool(
                minconn=1,
                maxconn=20,
                dsn=os.getenv("DB_DSN")
            )
        except (Exception, psycopg2.DatabaseError) as error:
            print("Error while connecting to PostgreSQL", error)
            raise error

def get_db_connection():
    """Gets a connection from the connection pool.

    Returns:
        psycopg2.extensions.connection: A connection object to the database.
    """
    global _pool
    if _pool is None:
        init_db_pool()
    
    return _pool.getconn()

def release_db_connection(conn):
    """Releases the connection back to the pool.

    Args:
        conn (psycopg2.extensions.connection): The connection to release.
    """
    global _pool
    if _pool and conn:
        try:
            _pool.putconn(conn)
        except Exception as e:
            print(f"Error releasing connection: {e}")

def close_pool():
    """Closes the connection pool."""
    global _pool
    if _pool:
        _pool.closeall()
