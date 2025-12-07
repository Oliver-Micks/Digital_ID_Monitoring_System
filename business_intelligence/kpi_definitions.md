# KPI Definitions

## Primary KPIs

### 1. Agency Compliance Rate
**Definition:** Percentage of authorized access attempts vs. total attempts for an agency

**Calculation:**
```sql
(Authorized Access / Total Access Attempts) × 100
```

**Target:** ≥ 95%  
**Alert Threshold:** < 85%

**SQL Query:**
```sql
SELECT 
    agency_name,
    ROUND((SUM(CASE WHEN auth_status='YES' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) as compliance_rate
FROM access_audit_log aal
JOIN agency_employees ae ON aal.employee_id = ae.employee_id
JOIN government_agencies ga ON ae.agency_id = ga.agency_id
GROUP BY ga.agency_id, agency_name;
```

---

### 2. Violation Detection Rate
**Definition:** Percentage of unauthorized access attempts that are auto-detected and flagged

**Calculation:**
```sql
(Violations Created / Denied Access Attempts) × 100
```

**Target:** 100%  
**Alert Threshold:** < 95%

---

### 3. After-Hours Access Count
**Definition:** Number of access attempts between 8 PM - 6 AM

**Calculation:**
```sql
COUNT(access_time WHERE HOUR >= 20 OR HOUR < 6)
```

**Target:** < 20 per day  
**Alert Threshold:** > 50 per day

**SQL Query:**
```sql
SELECT COUNT(*) as after_hours_access
FROM access_audit_log
WHERE TO_NUMBER(TO_CHAR(access_time, 'HH24')) >= 20 
   OR TO_NUMBER(TO_CHAR(access_time, 'HH24')) < 6;
```

---

### 4. High-Severity Violations
**Definition:** Count of violations with severity = 'HIGH'

**Target:** < 5 per month  
**Alert Threshold:** > 10 per month

**SQL Query:**
```sql
SELECT COUNT(*) as high_severity_violations
FROM privacy_violations
WHERE severity = 'HIGH'
  AND created_at >= TRUNC(SYSDATE, 'MM');
```

---

### 5. Permission Expiry Alert
**Definition:** Number of permissions expiring within 30 days

**Target:** < 10  
**Alert Threshold:** > 20

**SQL Query:**
```sql
SELECT COUNT(*) as expiring_soon
FROM access_permissions
WHERE expiry_date BETWEEN SYSDATE AND SYSDATE + 30;
```

---

## Secondary KPIs

### 6. Average Access Per Citizen
**Definition:** Average number of times each citizen's data is accessed

**Calculation:**
```sql
Total Access Attempts / Unique Citizens Accessed
```

**Purpose:** Measure surveillance intensity

---

### 7. Employee Access Distribution
**Definition:** Access attempts per employee

**Purpose:** Identify unusually active users

**SQL Query:**
```sql
SELECT emp_name, COUNT(*) as access_count
FROM access_audit_log aal
JOIN agency_employees ae ON aal.employee_id = ae.employee_id
GROUP BY emp_name
ORDER BY access_count DESC;
```

---

### 8. Data Category Request Distribution
**Definition:** Access attempts by data category (FINANCIAL, HEALTH, BIOMETRIC, PERSONAL)

**Purpose:** Understand which data types are most requested

**SQL Query:**
```sql
SELECT data_category, COUNT(*) as request_count
FROM access_audit_log
WHERE data_category IS NOT NULL
GROUP BY data_category
ORDER BY request_count DESC;
```

---

### 9. Violation Resolution Time
**Definition:** Average days from violation creation to resolution

**Calculation:**
```sql
AVG(resolution_date - created_at) WHERE resolved_status = 'RESOLVED'
```

**Target:** < 7 days

---

### 10. Permission Utilization Rate
**Definition:** Percentage of granted permissions actually used

**Calculation:**
```sql
(Permissions Used / Total Permissions) × 100
```

**Purpose:** Identify unused permissions for revocation

---

## KPI Dashboard Summary

| KPI | Current | Target | Status |
|:---|:---|:---|:---|
| Agency Compliance Rate | 94.2% | ≥ 95% | 🟡 Warning |
| Violation Detection Rate | 100% | 100% | 🟢 Good |
| After-Hours Access (Daily) | 18 | < 20 | 🟢 Good |
| High-Severity Violations (Monthly) | 12 | < 5 | 🔴 Alert |
| Permissions Expiring (30 Days) | 8 | < 10 | 🟢 Good |

---

