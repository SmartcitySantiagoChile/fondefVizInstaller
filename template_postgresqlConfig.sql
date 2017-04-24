CREATE DATABASE <DATABASE>;
CREATE USER <USER> WITH PASSWORD '<PASSWORD>';
GRANT ALL PRIVILEGES ON DATABASE <DATABASE> TO <USER>;
ALTER USER <USER> CREATEDB;
ALTER ROLE <USER> SUPERUSER;
\q