# PDB Setup Guide

## Database Configuration

**PDB Name:** `Mon_27119_Olivier_DigitalID_db`  
**Admin User:** `digital_id_admin` / Password: `Olivier`  
**App User:** `digital_id_user` / Password: `Olivier2025`

---

## Step 1: Create PDB

```sql
-- Connect as SYSDBA
CONNECT sys AS SYSDBA

-- Create PDB
CREATE PLUGGABLE DATABASE Mon_27119_Olivier_DigitalID_db
ADMIN USER digital_id_admin IDENTIFIED BY Olivier
FILE_NAME_CONVERT = ('pdbseed', 'Mon_27119_Olivier_DigitalID_db')
STORAGE (MAXSIZE 2G);

-- Open PDB
ALTER PLUGGABLE DATABASE Mon_27119_Olivier_DigitalID_db OPEN;
ALTER PLUGGABLE DATABASE Mon_27119_Olivier_DigitalID_db SAVE STATE;

-- Verify
SELECT name, open_mode FROM v$pdbs;
```

---

## Step 2: Create Tablespaces

```sql
-- Switch to PDB
ALTER SESSION SET CONTAINER = Mon_27119_Olivier_DigitalID_db;

-- Data tablespace
CREATE TABLESPACE digital_id_data
DATAFILE SIZE 50M AUTOEXTEND ON NEXT 10M MAXSIZE 500M;

-- Index tablespace
CREATE TABLESPACE digital_id_indexes
DATAFILE SIZE 30M AUTOEXTEND ON NEXT 5M MAXSIZE 200M;
```

---

## Step 3: Create Application User

```sql
CREATE USER digital_id_user IDENTIFIED BY Olivier2025
DEFAULT TABLESPACE digital_id_data
TEMPORARY TABLESPACE temp
QUOTA UNLIMITED ON digital_id_data
QUOTA UNLIMITED ON digital_id_indexes;

-- Grant privileges
GRANT CONNECT, RESOURCE TO digital_id_user;
GRANT CREATE VIEW, CREATE SEQUENCE, CREATE PROCEDURE, CREATE TRIGGER TO digital_id_user;
```

---

## Step 4: Run Database Scripts

```sql
-- Connect as application user
CONNECT digital_id_user/Olivier@Mon_27119_Olivier_DigitalID_db

-- Execute scripts in order
@02_create_tables.sql
@03_insert_data.sql
@04_validation_queries.sql
@05_plsql_logic.sql
@06_triggers_audit.sql
```

---

## Connection Strings

**SQL Developer:**
```
Hostname:  192.168.56.1/localhost
Port: 1521
Service name: Mon_27119_Olivier_DigitalID_db
Username: digital_id_user
Password: Olivier
```

**SQL*Plus:**
```bash
sqlplus digital_id_user/Olivier@localhost:1521/Mon_27119_Olivier_DigitalID_db
```

---

## Troubleshooting

**PDB not open:**
```sql
ALTER PLUGGABLE DATABASE Mon_27119_Olivier_DigitalID_db OPEN;
```

**Insufficient privileges:**
```sql
GRANT ALL PRIVILEGES TO digital_id_user;
```

---
