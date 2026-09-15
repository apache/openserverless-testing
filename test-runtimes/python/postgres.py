# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
import pg8000.dbapi

from urllib.parse import urlparse, unquote

def connect(postgres_url):
    """
    Opens a pg8000 connection from the given postgres URL. pg8000 takes
    connection arguments as keywords, so the URL is parsed here.
    """
    url = urlparse(postgres_url)
    return pg8000.dbapi.connect(
        host=url.hostname,
        port=url.port or 5432,
        user=unquote(url.username) if url.username else None,
        password=unquote(url.password) if url.password else None,
        database=url.path.lstrip("/") or None,
    )

def main(args):

    response = {"body": {}}

    conn = connect(args.get("postgres_url"))
    try:
        # Open a cursor to perform database operations
        cur = conn.cursor()
        try:
            # pg8000 uses the extended query protocol: one statement per execute()
            cur.execute("CREATE SCHEMA IF NOT EXISTS openserverless")
            cur.execute("SET search_path TO openserverless")

            # Execute a command: this creates a new table
            cur.execute('CREATE EXTENSION IF NOT EXISTS "pgcrypto"')
            cur.execute("""
                CREATE TABLE IF NOT EXISTS openserverless_table (
                    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    message varchar(100)
                )
                """)

            # Pass data to fill a query placeholders and let pg8000 perform
            # the correct conversion (no SQL injections!)
            cur.execute("INSERT INTO openserverless_table(message) VALUES(%s)",
                        ("OpenServerless Postgres is up and running!",))

            # Query the database and obtain data as Python objects.
            cur.execute("SELECT message FROM openserverless_table")
            record = cur.fetchone()[0]

            cur.execute("DROP table openserverless_table")
            cur.execute("DROP SCHEMA openserverless CASCADE")

            response["body"] = record
            # Make the changes to the database persistent
            conn.commit()
        finally:
            cur.close()
    finally:
        conn.close()

    return response
