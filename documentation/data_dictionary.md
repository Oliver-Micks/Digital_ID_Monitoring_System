
# Data Dictionary

#### [View The ER Diagram](../screenshots/database_objects/er_diagram.drawio.jpg)
## 1. Table: CITIZENS
Stores the core identity information for Rwandan citizens.

| Column Name | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `CITIZEN_ID` | NUMBER(10) | **PK**, NOT NULL | Unique internal identifier for the citizen. |
| `FULL_NAME` | VARCHAR2(100) | NOT NULL | Official full name as per National ID. |
| `DOB` | DATE | NULL | Date of Birth. |
| `PHONE` | VARCHAR2(20) | UNIQUE | Contact mobile number. |
| `EMAIL` | VARCHAR2(100) | NULL | Personal email address. |
| `DISTRICT` | VARCHAR2(50) | NULL | Residential district (e.g., Gasabo). |
| `STATUS` | VARCHAR2(20) | DEFAULT 'ACTIVE' | Current status (ACTIVE, DECEASED, BLOCKED). |

## 2. Table: GOVERNMENT_AGENCIES
List of authorized entities allowed to request data.

| Column Name | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `AGENCY_ID` | NUMBER(10) | **PK**, NOT NULL | Unique identifier for the agency. |
| `AGENCY_NAME` | VARCHAR2(100) | UNIQUE, NOT NULL | Official Name (e.g., RRA, RSSB). |
| `AGENCY_TYPE` | VARCHAR2(50) | NOT NULL | Category (TAX, HEALTH, SECURITY). |
| `AUTH_LEVEL` | NUMBER(2) | NULL | Numeric rank determining data access depth. |

## 3. Table: AGENCY_EMPLOYEES
System users who perform the data access requests.

| Column Name | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `EMPLOYEE_ID` | NUMBER(10) | **PK**, NOT NULL | Unique identifier for the employee. |
| `AGENCY_ID` | NUMBER(10) | **FK** (Ref AGENCIES) | The agency this employee works for. |
| `EMP_NAME` | VARCHAR2(100) | NOT NULL | Full name of the employee. |
| `POSITION` | VARCHAR2(50) | NULL | Job title (e.g., Tax Auditor). |
| `USERNAME` | VARCHAR2(50) | UNIQUE, NOT NULL | System login username. |

## 4. Table: ACCESS_PERMISSIONS
The "Rulebook" defining who can see what.

| Column Name | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `PERMISSION_ID`| NUMBER(10) | **PK**, NOT NULL | Unique ID for the permission rule. |
| `AGENCY_ID` | NUMBER(10) | **FK** (Ref Gov_Agencies) | Agency with the permission |
| `DATA_CATEGORY`| VARCHAR2(20) | CHECK (In List) | Type: FINANCIAL, HEALTH, PERSONAL, BIOMETRIC. |
| `PURPOSE` | VARCHAR2(200)| NOT NULL | Reason for granting access. |
| `EXPIRY_DATE` | DATE | NOT NULL | Date when permission automatically revokes. |
| `CREATED_BY` | VARCHAR2(50) | DEFAULT 'SYSTEM' | Who created this permission |
| `CREATED_AT` | DATE | DEFAULT SYSDATE | When permission was created |

## 5. Table: ACCESS_AUDIT_LOG
Immutable history of all access attempts (Success or Fail).

| Column Name | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `AUDIT_ID` | NUMBER(12) | **PK**, NOT NULL | Unique Log ID. |
| `EMPLOYEE_ID` | NUMBER(10) | **FK** (Ref EMPLOYEES)| Who attempted access. |
| `CITIZEN_ID` | NUMBER(10) | **FK** (Ref CITIZENS) | Whose data was requested. |
| `ACCESS_TIME` | DATE | DEFAULT SYSDATE | Exact timestamp of the attempt. |
| `ACTION` | VARCHAR2(50) | NOT NULL | Type of action (VIEW, UPDATE, QUERY). |
| `AUTH_STATUS` | VARCHAR2(10) | CHECK ('YES','NO') | Was the access allowed? |
| `NOTES` | VARCHAR2(400)| NULL | System generated notes or error messages. |

## 6. Table: PRIVACY_VIOLATIONS
Alerts generated when unauthorized access is detected.

| Column Name | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `VIOLATION_ID` | NUMBER(12) | **PK**, NOT NULL | Unique Violation ID. |
| `AUDIT_ID` | NUMBER(12) | **FK** (Ref AUDIT_LOG)| Link to the specific log entry. |
| `VIOLATION_TYPE`| VARCHAR2(100)| NOT NULL | Reason (AFTER_HOURS, NO_PERMISSION). |
| `SEVERITY` | VARCHAR2(20) | CHECK (L, M, H) | Severity level: LOW, MEDIUM, HIGH. |
| `RESOLVED_STATUS`| VARCHAR2(20)| DEFAULT 'OPEN' | Status of investigation. |