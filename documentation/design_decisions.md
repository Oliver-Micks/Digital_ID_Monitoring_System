# Design Decisions

## 1. Permission Model: Agency-Level Access

### Design Choice
Permissions are granted to **agencies**

**ACCESS_PERMISSIONS Structure:**
```sql
permission_id
agency_id        -- Which agency
data_category    -- What data type (FINANCIAL, HEALTH, etc.)
expiry_date      -- When permission expires
```

### Rationale
- **Realistic:** Rwanda's Digital ID system works this way. RRA has legal authority to access all financial data.
- **Scalable:** 10 agency permissions vs. 10,000+ citizen-agency combinations.
- **Maintainable:** Update 1 agency permission, not thousands of citizen records.
- **Performance:** Faster queries with fewer rows.

### What We Still Track Per-Citizen
Even though permissions are agency-level, we maintain complete transparency:
- **ACCESS_AUDIT_LOG** records every single access attempt per citizen
- Citizens can see exactly who accessed their data and when
- Full audit trail for compliance and investigations

---

## 2. Normalization: 3NF

### Design Choice
All tables normalized to **Third Normal Form (3NF)**.

### Key Principles Applied

**1NF - Atomic Values:**
- No multi-valued attributes
- Example: One phone number per citizen record

**2NF - No Partial Dependencies:**
- All tables use single-column primary keys
- No composite keys used

**3NF - No Transitive Dependencies:**
- Agency name stored only in `GOVERNMENT_AGENCIES`, not duplicated in `AGENCY_EMPLOYEES`
- Citizen details stored only in `CITIZENS`, not duplicated in `ACCESS_AUDIT_LOG`

### Benefits
- **Data Integrity:** Update agency name once, reflects everywhere
- **Storage Efficiency:** Audit logs don't repeat VARCHAR2(100) names millions of times
- **Consistency:** No risk of conflicting data across tables

---

## 3. Audit Log Immutability

### Design Choice
Audit logs can **never be deleted**.

**Implementation:**
```sql
CREATE OR REPLACE TRIGGER trg_protect_audit_log
BEFORE DELETE ON access_audit_log
BEGIN
    RAISE_APPLICATION_ERROR(-20003, 'Audit logs are IMMUTABLE');
END;
```

### Rationale
- **Legal Compliance:** Required for forensic investigations
- **Tamper-Proof:** Prevents covering up security incidents
- **Trust:** Citizens can rely on complete access history

---

## 4. Automated Violation Detection

### Design Choice
Every denied access attempt **automatically** creates a violation record.

**Implementation:**
```sql
CREATE OR REPLACE TRIGGER trg_auto_create_violation
AFTER INSERT ON access_audit_log
FOR EACH ROW
WHEN (NEW.auth_status = 'NO')
BEGIN
    INSERT INTO privacy_violations (...);
END;
```

### Rationale
- **Zero Human Error:** No manual flagging required
- **Real-Time Alerts:** Immediate notification of security incidents
- **Pattern Detection:** Multiple denials = suspicious behavior

---

## 5. After-Hours Detection

### Design Choice
Access between **8 PM - 6 AM** is flagged as higher risk.

**Implementation:**
```sql
FUNCTION fn_is_after_hours(p_timestamp DATE) RETURN BOOLEAN IS
    v_hour NUMBER;
BEGIN
    v_hour := TO_NUMBER(TO_CHAR(p_timestamp, 'HH24'));
    RETURN (v_hour >= 20 OR v_hour < 6);
END;
```

### Rationale
- Most legitimate government work happens 8 AM - 6 PM
- After-hours access could indicate unauthorized personal use or data theft
- Violations during after-hours automatically marked as HIGH severity

---

## 6. Weekend and Holiday Restrictions

### Design Choice
Data modifications on `CITIZENS` table blocked during:
- **Weekdays** (Monday-Friday)
- **Public Holidays**

**Implementation:**
- `public_holidays` table stores all holidays
- `fn_check_dml_restriction()` checks both weekdays and holidays
- Trigger blocks INSERT/UPDATE/DELETE if restricted

### Rationale
- Prevent unauthorized modifications during business hours
- Reduce risk of accidental data changes during operations
- Emergency modifications can be scheduled for weekends
- Holiday table provides flexibility (add new holidays without code changes)

---

## 7. Data Types

### VARCHAR2 Sizing
| Column | Size | Reason |
|:---|:---|:---|
| `full_name` | VARCHAR2(100) | Rwandan names typically 20-50 chars |
| `agency_name` | VARCHAR2(100) | "Ministry of Health" = 19 chars |
| `data_category` | VARCHAR2(20) | Longest value: 'BIOMETRIC' (10 chars) |
| `phone` | VARCHAR2(20) | "+250 781 234 567" with spaces |

**Guideline:** Smallest size that fits realistic data + buffer.

### DATE vs TIMESTAMP
| Column | Type | Reason |
|:---|:---|:---|
| `dob` | DATE | Day-level precision sufficient |
| `expiry_date` | DATE | Permissions expire at day-level |
| `access_time` | TIMESTAMP | Need exact time for auditing |

---

## 8. PL/SQL Organization

### Functions vs Procedures

**Functions:** Return values, no DML
- `fn_get_district_count()` - Calculate population
- `fn_has_permission()` - Check authorization
- `fn_is_after_hours()` - Time validation

**Procedures:** Perform actions, may COMMIT
- `sp_register_citizen()` - INSERT new citizen
- `sp_validate_access()` - Check + log access
- `sp_update_citizen_district()` - UPDATE location

### Packages vs Standalone

**Package:** Related procedures grouped together
- `pkg_audit_tools` - Compliance and archiving functions

**Standalone:** General-purpose utilities
- Individual procedures/functions used across contexts

---

## 9. Trigger Design

### Simple Triggers
Single action at one timing point:
- `trg_restrict_weekday_holiday` - Block DML
- `trg_auto_create_violation` - Create violation record
- `trg_protect_audit_log` - Prevent deletions

### Compound Trigger
Multiple timing points in one trigger:
- `trg_audit_citizen_dml` - Logs at BEFORE STATEMENT, BEFORE EACH ROW, AFTER EACH ROW, AFTER STATEMENT

**When to use compound:**
- Need to share variables across timing points
- Perform both validation and logging

---

## 10. Error Handling

### Custom Error Codes
```sql
-20001: Weekday restriction
-20002: Holiday restriction
-20003: Audit log immutability violation
```

### Silent Fail vs Loud Fail

**Silent (Return FALSE):**
```sql
-- Validation functions default to FALSE = deny access
FUNCTION fn_has_permission RETURN BOOLEAN IS
...
EXCEPTION
    WHEN OTHERS THEN RETURN FALSE;
END;
```

**Loud (Raise Error):**
```sql
-- Triggers block operations with clear messages
TRIGGER trg_restrict_weekday_holiday
...
    RAISE_APPLICATION_ERROR(-20001, 'Weekday restriction');
END;
```

---

## 11. Indexing Strategy

### What We Index
✅ All primary keys (automatic)  
✅ All foreign keys (manual, for JOIN performance)  
✅ `access_time` (frequent WHERE/ORDER BY)  
✅ `auth_status` (filter unauthorized access)  
✅ `expiry_date` (find expired permissions)

### What We Don't Index
❌ `full_name` (rarely queried, text search not needed)  
❌ `notes` (VARCHAR2(400), too large)  
❌ `status` (only 2 values: not selective)

---

## 12. Testing Approach

### Inline Tests
Tests included at end of each phase script:
- ✅ Easy for instructor to run and verify
- ✅ Self-documenting (shows expected behavior)
- ✅ Immediate verification during development

### Test Data Volume
- Citizens: 100-200 records
- Agencies: 10-15 records
- Employees: 50-100 records
- Audit Logs: 500-1,000 records

**Sufficient to demonstrate:**
- Window functions (rankings, trends)
- Business rules (denials, violations)
- Performance (queries remain fast)

---

