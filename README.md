# Digital ID Data Privacy and Access Monitoring System

![Oracle](https://img.shields.io/badge/Database-Oracle%2021c-red)
![Language](https://img.shields.io/badge/Language-PL%2FSQL-orange)
![Institution](https://img.shields.io/badge/Institution-AUCA-blue)
![Course](https://img.shields.io/badge/Course-INSY%208311-green)

> **Capstone Project | Database Development with PL/SQL**  
> *Adventist University of Central Africa (AUCA)*

---

## 👤 Author Information

| Field | Detail |
|:---|:---|
| **Student Name** | **Byiringiro Niyonagize Olivier** |
| **Student ID** | **27119** |
| **Group** | Monday (A) |
| **Lecturer** | Eric Maniraguha |
| **Database PDB** | `Mon_27119_Olivier_DigitalID_db` |

---

## 📑 Table of Contents
1. [Project Overview](#-project-overview)
2. [Key Objectives](#-key-objectives)
3. [System Architecture](#-system-architecture)
4. [Technical Stack](#-technical-stack)
5. [Security Features](#-security-features)
6. [Folder Structure](#-folder-structure)
7. [Documentation & BI](#-documentation--bi)
8. [Screenshots](#-screenshots)
9. [Quick Start Guide](#-quick-start-guide)

---

## 📖 Project Overview

### 🚩 Problem Statement
Rwanda is rolling out Digital National IDs under the **NST2** program, centralizing sensitive biometric, health, and financial data. Currently, there is **no transparent mechanism** to monitor which government agencies (like RRA, MINISANTE, RIB) access citizen data. This lack of oversight creates risks for unauthorized access, data misuse, and privacy violations without citizen awareness or agency accountability.

### 💡 Proposed Solution
This project implements a secure **PL/SQL Oracle Database System** that monitors and controls government agency access to citizen data. It introduces a **Policy-Based Access Control System** where agencies are authorized to access specific data categories (e.g., RRA → Financial Data, MINISANTE → Health Data) based on their legal mandate and operational needs. 

The system features:
- **Agency-Level Permissions:** Each government agency receives access rights to specific data categories with strict expiry dates
- **Immutable Audit Logging:** Every data access attempt is recorded with timestamp, employee details, and authorization status
- **Automated Violation Detection:** PL/SQL triggers and procedures flag suspicious activities (after-hours access, unauthorized attempts, bulk downloads)
- **Transparency Dashboard:** BI analytics provide oversight of agency access patterns and compliance rates

---

## 🎯 Key Objectives

* **Mandate-Based Authorization:** Government agencies receive access permissions aligned with their legal responsibilities
* **Comprehensive Auditing:** A tamper-proof `ACCESS_AUDIT_LOG` records every single data access attempt (Who, When, Why, Authorized/Denied)
* **Automated Violation Detection:** Real-time flagging of suspicious activities through PL/SQL triggers and stored procedures
* **Agency Accountability:** BI Dashboards provide transparency on which agencies access citizen data most frequently
* **Compliance Monitoring:** Track agency compliance rates and identify patterns of unauthorized access attempts

---

## 🏗 System Architecture

The database is built on a **3NF Normalized Schema** implementing **Agency-Level Permissions**. This design reflects how real-world digital ID systems operate, where agencies have fixed mandates. 

### Core Tables (6 entities)
1. **CITIZENS** — Core identity data for all registered citizens
2. **GOVERNMENT_AGENCIES** — Authorized entities (RRA, MINISANTE, RIB, Banks, etc.)
3. **AGENCY_EMPLOYEES** — Government workers who access the system
4. **ACCESS_PERMISSIONS** — Agency authorization rules (which agency can access which data category)
5. **ACCESS_AUDIT_LOG** — Immutable record of all access attempts
6. **PRIVACY_VIOLATIONS** — Automated alerts for security breaches


---

## ⚙️ Technical Stack

| Component | Technology |
|:---|:---|
| **Database** | Oracle Database 21c XE |
| **Language** | PL/SQL (Procedures, Functions, Packages, Triggers) |
| **Version Control** | GitHub |
| **Development Tools** | Oracle SQL Developer |
| **Monitoring** | Oracle Enterprise Manager (OEM) |
| **BI Tools** | SQL Analytics + Mockup Dashboards |
| **Normalization** | 3NF (Third Normal Form) |

---

## 🔒 Security Features

### Access Control
- **Agency-Level Permissions:** Only authorized agencies can access specific data categories
- **Employee Authentication:** All access tied to individual employee accounts
- **Expiry Date Enforcement:** Permissions automatically expire and require renewal
- **Role-Based Access Levels:** Employees have hierarchical access levels within their agency

### Audit & Monitoring
- **Tamper-Proof Logging:** All access attempts recorded with `SYSTIMESTAMP`
- **Authorization Status Tracking:** Every access marked as 'YES' (authorized) or 'NO' (denied)
- **After-Hours Detection:** Automated flagging of access between 8 PM - 6 AM
- **Bulk Access Monitoring:** Alerts for suspicious high-volume queries

### Violation Detection
- **Automated Triggers:** Real-time detection of unauthorized access attempts
- **Severity Classification:** Violations categorized as LOW, MEDIUM, HIGH
- **Resolution Tracking:** Status management (OPEN → INVESTIGATING → RESOLVED)
- **Compliance Reporting:** Agency-level compliance rate calculations

---

## 📂 Folder Structure

```
Digital_ID_Monitoring_System/
│
├── README.md                                    # 📘 Project Overview & Setup Guide
│
├── database/
│   ├── scripts/                                 # ⚙️ Core SQL Scripts
│   │   ├── 01_create_pdb.sql                    # Phase 4 — PDB Creation
│   │   ├── 02_create_tables.sql                 # Phase 5 — Table Structures
│   │   ├── 03_insert_data.sql                   # Phase 5 — Sample Data Population
│   │   ├── 04_validation.sql                    # Phase 5 — Integrity & Validation Checks
│   │   ├── 05_procedures_functions.sql          # Phase 6 — Procedures, Functions, Packages
│   │   ├── 06_triggers.sql                      # Phase 7 — Triggers & Business Rules
│   │
│   └── documentation/                           # 📘 DB Setup Documentation
│       └── pdb_setup.md                         # PDB configuration steps
│
├── queries/                                     # 🔍 Reporting & Auditing SQL
│   ├── data_retrieval.sql                       # Basic SELECT queries
│   ├── analytics_queries.sql                    # Complex joins & aggregations
│   └── audit_queries.sql                        # Security & compliance reports
│
├── business_intelligence/                       # 📊 BI Strategy & Dashboards
│   ├── bi_requirements.md                       # BI objectives & KPIs
│   ├── dashboards.md                            # Dashboard mockups
│   └── kpi_definitions.md                       # Key performance indicators
│
├── screenshots/                                 # 📸 Implementation Evidence
│   ├── database_objects/                        # ER_Diagrams, Business Model_Diagram
│   ├── test_results/                            # Execution outputs
│   └── oem_monitoring/                          # Oracle Enterprise Manager views
│
└── documentation/                               # 📚 System-Level Documentation
    ├── data_dictionary.md                       # All tables, columns, constraints
    ├── architecture.md                          # Architecture overview
    └── design_decisions.md                      # Reasons to choosing the design & other choices
```

---

## 📚 Documentation & BI

### Critical Note
Full technical details are available in the linked documents below.

| Document | Description |
|:---|:---|
| **Data Dictionary** | Detailed breakdown of all 6 tables, columns, data types, and constraints |
| **System Architecture** | High-level design diagrams (ERD) and relationship explanations |
| **Design Decisions** | Justification for the design, 3NF normalization, security logic |
| **BI Requirements** | KPI definitions and dashboard mockups for decision support |

---

## 📸 Screenshots

### Planned Evidence
1. **Database Objects** (SQL Developer)
   - Tables list showing all 6 core tables
   - Procedures, functions, and packages in Object Navigator
   #### ![Database](/screenshots/database_objects/tables_list.png)
   
2. **ER Diagram**
   - Complete entity-relationship diagram with cardinalities
   - Primary and foreign key relationships
   #### ![ER Diagram](/screenshots/database_objects/ER_Diagram_dev.png)

3. **Test Results**
   - Procedure execution outputs with DBMS_OUTPUT
   - Audit log query results showing access attempts
   - Violation detection examples

4. **OEM Monitoring**
   - Database performance metrics
   - Session monitoring
   - Storage usage
   #### ![OEM Monitoring](/screenshots/oem_monitoring/oem_dashboard.png)

---

## 🚀 Quick Start Guide

Follow these steps to deploy the project locally.

### Prerequisites
- Oracle Database 21c (XE or Enterprise Edition)
- Oracle SQL Developer
- GitHub account

### Step 1: Database Creation

1. Open SQL Developer and connect as `SYSDBA`
2. Run `database/scripts/01_create_pdb.sql` to create the PDB and Admin User
3. Verify PDB is open: 
   ```sql
   SELECT name, open_mode FROM v$pdbs;
   ```

### Step 2: Schema Implementation

1. Connect as `digital_id_user`
2. Run `database/scripts/02_create_tables.sql` to build the structure
3. Run `database/scripts/03_insert_data.sql` to load 100+ sample records
4. Run `database/scripts/04_validation.sql` to confirm data integrity

### Step 3: PL/SQL Logic

1. Run `database/scripts/05_procedures_functions.sql` to create procedures, functions, packages
2. Run `database/scripts/06_triggers.sql` to implement business rules

### Step 4: Testing

1. Execute test blocks at the end of each script
2. Verify outputs using `SET SERVEROUTPUT ON`
3. Run audit queries to confirm logging works

### Step 5: Documentation

1. Update `documentation/data_dictionary.md` with actual table structures
2. Generate ER diagram and save to `documentation/`
3. Take screenshots and organize in `screenshots/` folder

---

## 📊 Business Intelligence

### Key Performance Indicators (KPIs)
- **Agency Compliance Rate:** % of authorized vs. total access attempts per agency
- **Citizen Data Access Frequency:** Average number of times citizen data is accessed per month
- **Violation Rate:** Number of violations per 1,000 access attempts
- **After-Hours Access:** % of access attempts outside business hours
- **Top Violating Agencies:** Ranked list of agencies with most violations

### Dashboard Mockups
1. **Executive Summary:** KPI cards showing total citizens, agencies, access attempts, violations
2. **Audit Dashboard:** Real-time access attempts, authorization status distribution, top employees
3. **Compliance Dashboard:** Agency compliance rates, violation trends, resolution status
4. **Citizen Privacy Dashboard:** Data access frequency by category, agency access patterns

---
