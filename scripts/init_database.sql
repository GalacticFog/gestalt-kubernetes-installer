-- Assume databases have been dropped

-- drop database if exists "gestalt-security";
create database "gestalt-security";
\c "gestalt-security";
drop extension if exists "pgcrypto";
drop extension if exists "uuid-ossp";

-- drop database if exists "gestalt-meta";
create database "gestalt-meta";
\c "gestalt-meta";
