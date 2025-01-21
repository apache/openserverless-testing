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
import psycopg

def main(args):

    response = {"body": {}}

    with psycopg.connect(args.get("postgres_url")) as conn:

        # Open a cursor to perform database operations
        with conn.cursor() as cur:
            cur.execute("""CREATE SCHEMA IF NOT EXISTS nuvolaris;
            SET search_path TO nuvolaris;
            """)

            # Execute a command: this creates a new table
            cur.execute("""
                CREATE EXTENSION IF NOT EXISTS "pgcrypto";
                CREATE TABLE IF NOT EXISTS nuvolaris_table (
                    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    message varchar(100)        
                );
                """)

            # Pass data to fill a query placeholders and let Psycopg perform
            # the correct conversion (no SQL injections!)
            cur.execute("INSERT INTO nuvolaris_table(message) VALUES(%(message)s)",{"message":"Nuvolaris Postgres is up and running!"})
            # Make the changes to the database persistent

            # Query the database and obtain data as Python objects.
            cur.execute("SELECT message FROM nuvolaris_table")
            record = cur.fetchone()[0]

            cur.execute("DROP table nuvolaris_table")
            cur.execute("DROP SCHEMA nuvolaris CASCADE")

            response["body"] = record
            conn.commit()

    return response