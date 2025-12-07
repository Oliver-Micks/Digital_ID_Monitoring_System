# System Architecture

## Overview
The **Digital ID Data Privacy System** is built on an Oracle Database, using a clear four-layer structure to separate its functions. This design ensures the system is secure, easy to maintain, and ready to grow.

---

## 1. System Structure

The system is organized into four logical layers, starting from the user interface down to the physical database engine.

| Layer | What It Does (Role) | Key Components |
| :--- | :--- | :--- |
| **4. Interface Layer** | Shows reports and lets citizens manage their data. (Conceptual) | BI Dashboards, Citizen Portal |
| **3. Application Layer** | **Enforces all the security and business rules.** (Code) | **PL/SQL** Procedures, Functions, Packages |
| **2. Data Layer** | Stores all the information and security rules. | Tables, Indexes, Triggers, Constraints |
| **1. Infrastructure Layer** | The core environment where the database runs. | Oracle 21c PDB, Tablespaces, Archive Log |

---

## 2. Key Components

### 2.1. Database Engine and Setup (Infrastructure Layer)
* **Database:** Uses Oracle 21c and is kept separate in a **Pluggable Database (PDB)** called `Mon_27119_Olivier_DigitalID_db`.
* **Storage:** Data is organized into two areas: `tbs_data` (for citizen records) and `tbs_idx` (for speeding up lookups).
* **Audit Compliance:** **Archive logging is enabled** to ensure a full history of database changes is kept, which is required for external audits.

### 2.2. Data Storage (Data Layer)
The system uses six main tables, which are organized to prevent data duplication and errors:

* **CITIZENS:** Holds all core identity information.
* **ACCESS_PERMISSIONS:** The "rulebook" that defines which agency can see what data and until when it expires.
* **ACCESS_AUDIT_LOG:** The **tamper-proof history** that records every single access attempt (successful or failed).
* **PRIVACY_VIOLATIONS:** Records all security incidents, like unauthorized access attempts.

### 2.3. The Rules and Logic (Application Layer)
This is where the code (PL/SQL) ensures the system behaves correctly:

* **Procedures:** These are used to run complex actions, like checking a request against permissions, logging the result, and then either allowing or blocking the access.
* **Triggers:** These fire automatically to enforce rules, such as:
    * Logging every action immediately into `ACCESS_AUDIT_LOG`.
    * Creating a **Violation** record if access is denied.
    * **Blocking anyone** from deleting records from the `ACCESS_AUDIT_LOG`.
* **Reporting:** PL/SQL Packages group together functions that calculate scores (like Agency Compliance) and rank employees (like Top Violators) for the dashboards.

---

## 3. Data Flow and Security

### Access Request Flow
This is the sequence for every data request:

1.  **Request:** An Agency Employee asks for a citizen's data.
2.  **Validation:** The system checks: 1) Does the agency have permission? 2) Is the permission still valid (not expired)?
3.  **Logging:** The attempt is recorded in the `ACCESS_AUDIT_LOG` immediately.
4.  **Decision:** Access is either **granted** or **blocked**. If blocked, a **Violation Alert** is also created.

### Security Principles
* **Immutable Auditing:** The `ACCESS_AUDIT_LOG` cannot be changed or deleted, ensuring complete accountability.
* **Permission Control:** Access is automatically removed when the `EXPIRY_DATE` is reached.
* **Least Privilege:** Employees can only use the data their agency is specifically authorized for.
* **After-Hours Detection:** The system flags any data access happening late at night (e.g., after 8 PM) as higher risk.