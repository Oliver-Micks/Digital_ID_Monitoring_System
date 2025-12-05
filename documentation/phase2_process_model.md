# Phase II — Business Process Modeling

## 1. Overview
This process models how agency employees request access to citizen Digital ID data, how the system validates permissions, returns data, and logs accesses and violations. 
### Actors: Agency Employee, Digital ID System, Audit & Security.

#### [View Process Flow Diagram](../screenshots/database_objects/phase2_diagram%20(1).jpg)

## 2. Process Steps
**Step 1 — Request:**  
Employee submits: `citizen_id`, `category` (PERSONAL|HEALTH|FINANCIAL|BIOMETRIC), `reason`.

**Step 2 — Validation:**  
System checks `ACCESS_PERMISSIONS` for a matching, unexpired permission (`citizen_id`, `agency_id`, `category`, expiry_date >= today).

**Step 3 — Authorized:**  
- Retrieve data from `CITIZENS`.  
- Return data to employee.  
- Insert success record into `ACCESS_AUDIT_LOG`.

**Step 4 — Denied:**  
- Block query, raise custom exception.  
- Insert denied access into `ACCESS_AUDIT_LOG`.  
- Create a `PRIVACY_VIOLATIONS` record (type = UNAUTHORIZED_ACCESS).

**Step 5 — Post-processing:**  
- Periodic job `AUTO_EXPIRE_PERMISSIONS` removes/marks expired permissions.  
- `DETECT_BULK_ACCESS` scans audit log and creates violation records for suspicious patterns (>50/h, after-hours, cross-district).

## 3. Roles & Responsibilities
- **Agency Employee:** Requests data; provides reason.  
- **Digital ID System:** Validates permissions, retrieves data, writes audit logs, raises exceptions.  
- **Audit & Security:** Monitors logs, generates violations, provides reports to citizens.

## 4. MIS Relevance & Analytics
The system supports transparent governance and compliance. Analytics opportunities: access trends, violations heatmap, top offending employees/agencies.

