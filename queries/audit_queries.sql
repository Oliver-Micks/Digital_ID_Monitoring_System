-- ==================================================
-- AUDIT & SECURITY QUERIES
-- Queries for compliance monitoring and security auditing
-- ==================================================

SET LINESIZE 200
SET PAGESIZE 100
COL employee_name FORMAT A25
COL agency_name FORMAT A30
COL citizen_name FORMAT A25
COL action FORMAT A20
COL auth_status FORMAT A10
COL notes FORMAT A40

-- --------------------------------------------------
-- QUERY 1: Recent Unauthorized Access Attempts
-- --------------------------------------------------

SELECT 
    aal.audit_id,
    ae.emp_name as employee_name,
    ga.agency_name,
    c.full_name as citizen_name,
    aal.access_time,
    aal.action,
    aal.data_category,
    aal.auth_status,
    SUBSTR(aal.notes, 1, 40) as reason
FROM access_audit_log aal
JOIN agency_employees ae ON aal.employee_id = ae.employee_id
JOIN government_agencies ga ON ae.agency_id = ga.agency_id
JOIN citizens c ON aal.citizen_id = c.citizen_id
WHERE aal.auth_status = 'NO'
ORDER BY aal.access_time DESC
FETCH FIRST 20 ROWS ONLY;


-- --------------------------------------------------
-- QUERY 2: All Privacy Violations Requiring Action
-- --------------------------------------------------

SELECT 
    pv.violation_id,
    pv.violation_type,
    pv.severity,
    pv.resolved_status,
    ae.emp_name as violating_employee,
    ga.agency_name,
    c.full_name as affected_citizen,
    aal.access_time as violation_time,
    ROUND(SYSDATE - pv.created_at, 1) as days_open
FROM privacy_violations pv
JOIN access_audit_log aal ON pv.audit_id = aal.audit_id
JOIN agency_employees ae ON aal.employee_id = ae.employee_id
JOIN government_agencies ga ON ae.agency_id = ga.agency_id
JOIN citizens c ON aal.citizen_id = c.citizen_id
WHERE pv.resolved_status IN ('OPEN', 'INVESTIGATING')
ORDER BY 
    CASE pv.severity 
        WHEN 'HIGH' THEN 1 
        WHEN 'MEDIUM' THEN 2 
        WHEN 'LOW' THEN 3 
    END,
    pv.created_at DESC;


-- --------------------------------------------------
-- QUERY 3: Audit Log Completeness Check
-- --------------------------------------------------

SELECT 
    'Total Audit Entries' as metric,
    COUNT(*) as count,
    NULL as percentage
FROM access_audit_log
UNION ALL
SELECT 
    'Entries with NULL Data Category' as metric,
    COUNT(*) as count,
    ROUND((COUNT(*) / (SELECT COUNT(*) FROM access_audit_log)) * 100, 2) as percentage
FROM access_audit_log
WHERE data_category IS NULL
UNION ALL
SELECT 
    'Entries with NULL Notes' as metric,
    COUNT(*) as count,
    ROUND((COUNT(*) / (SELECT COUNT(*) FROM access_audit_log)) * 100, 2) as percentage
FROM access_audit_log
WHERE notes IS NULL
UNION ALL
SELECT 
    'Authorized Entries' as metric,
    COUNT(*) as count,
    ROUND((COUNT(*) / (SELECT COUNT(*) FROM access_audit_log)) * 100, 2) as percentage
FROM access_audit_log
WHERE auth_status = 'YES'
UNION ALL
SELECT 
    'Denied Entries' as metric,
    COUNT(*) as count,
    ROUND((COUNT(*) / (SELECT COUNT(*) FROM access_audit_log)) * 100, 2) as percentage
FROM access_audit_log
WHERE auth_status = 'NO';


-- --------------------------------------------------
-- QUERY 4: Employee Risk Profile
-- --------------------------------------------------

SELECT 
    ae.employee_id,
    ae.emp_name,
    ga.agency_name,
    COUNT(DISTINCT aal.audit_id) as total_access_attempts,
    SUM(CASE WHEN aal.auth_status = 'NO' THEN 1 ELSE 0 END) as unauthorized_attempts,
    COUNT(DISTINCT pv.violation_id) as total_violations,
    SUM(CASE WHEN pv.severity = 'HIGH' THEN 1 ELSE 0 END) as high_severity_violations,
    ROUND((SUM(CASE WHEN aal.auth_status = 'NO' THEN 1 ELSE 0 END) / COUNT(DISTINCT aal.audit_id)) * 100, 2) as violation_rate,
    CASE 
        WHEN COUNT(DISTINCT pv.violation_id) >= 10 THEN '🔴 CRITICAL RISK'
        WHEN COUNT(DISTINCT pv.violation_id) >= 5 THEN '🟠 HIGH RISK'
        WHEN COUNT(DISTINCT pv.violation_id) >= 2 THEN '🟡 MEDIUM RISK'
        WHEN COUNT(DISTINCT pv.violation_id) = 1 THEN '🟢 LOW RISK'
        ELSE '✅ NO VIOLATIONS'
    END as risk_assessment
FROM agency_employees ae
JOIN government_agencies ga ON ae.agency_id = ga.agency_id
LEFT JOIN access_audit_log aal ON ae.employee_id = aal.employee_id
LEFT JOIN privacy_violations pv ON aal.audit_id = pv.audit_id
GROUP BY ae.employee_id, ae.emp_name, ga.agency_name
HAVING COUNT(DISTINCT pv.violation_id) > 0
ORDER BY total_violations DESC, high_severity_violations DESC;


-- --------------------------------------------------
-- QUERY 5: Citizen Access Timeline
-- --------------------------------------------------

SELECT 
    aal.access_time,
    ae.emp_name as employee,
    ga.agency_name,
    aal.action,
    aal.data_category,
    aal.auth_status,
    CASE 
        WHEN pv.violation_id IS NOT NULL THEN '⚠️ VIOLATION'
        WHEN aal.auth_status = 'NO' THEN '❌ DENIED'
        ELSE '✅ AUTHORIZED'
    END as status_icon,
    SUBSTR(aal.notes, 1, 50) as notes
FROM access_audit_log aal
JOIN agency_employees ae ON aal.employee_id = ae.employee_id
JOIN government_agencies ga ON ae.agency_id = ga.agency_id
LEFT JOIN privacy_violations pv ON aal.audit_id = pv.audit_id
WHERE aal.citizen_id = 1  -- Change this to any citizen_id
ORDER BY aal.access_time DESC;


-- --------------------------------------------------
-- QUERY 6: Permission Compliance Audit
-- --------------------------------------------------

SELECT 
    ga.agency_name,
    aal.data_category,
    COUNT(*) as total_access_attempts,
    SUM(CASE WHEN aal.auth_status = 'YES' THEN 1 ELSE 0 END) as authorized,
    SUM(CASE WHEN aal.auth_status = 'NO' THEN 1 ELSE 0 END) as denied,
    CASE 
        WHEN ap.permission_id IS NOT NULL THEN '✅ HAS PERMISSION'
        ELSE '❌ NO PERMISSION'
    END as permission_status,
    ap.expiry_date
FROM access_audit_log aal
JOIN agency_employees ae ON aal.employee_id = ae.employee_id
JOIN government_agencies ga ON ae.agency_id = ga.agency_id
LEFT JOIN access_permissions ap ON ga.agency_id = ap.agency_id 
    AND aal.data_category = ap.data_category
    AND ap.expiry_date >= aal.access_time
WHERE aal.data_category IS NOT NULL
GROUP BY ga.agency_name, aal.data_category, ap.permission_id, ap.expiry_date
ORDER BY ga.agency_name, aal.data_category;


-- --------------------------------------------------
-- QUERY 7: After-Hours Access Audit
-- --------------------------------------------------

SELECT 
    TO_CHAR(aal.access_time, 'YYYY-MM-DD HH24:MI:SS') as access_timestamp,
    TO_CHAR(aal.access_time, 'HH24:MI') as time_only,
    ae.emp_name,
    ga.agency_name,
    c.full_name as citizen,
    aal.action,
    aal.auth_status,
    CASE 
        WHEN pv.violation_id IS NOT NULL THEN '⚠️ FLAGGED AS VIOLATION'
        ELSE 'Logged only'
    END as violation_status
FROM access_audit_log aal
JOIN agency_employees ae ON aal.employee_id = ae.employee_id
JOIN government_agencies ga ON ae.agency_id = ga.agency_id
JOIN citizens c ON aal.citizen_id = c.citizen_id
LEFT JOIN privacy_violations pv ON aal.audit_id = pv.audit_id
WHERE TO_NUMBER(TO_CHAR(aal.access_time, 'HH24')) >= 20 
   OR TO_NUMBER(TO_CHAR(aal.access_time, 'HH24')) < 6
ORDER BY aal.access_time DESC;


-- --------------------------------------------------
-- QUERY 8: DML Audit Log (Weekend/Holiday Restrictions)
-- --------------------------------------------------

SELECT 
    username,
    operation,
    table_name,
    attempt_time,
    status,
    day_type,
    reason
FROM dml_audit_log
WHERE attempt_time >= SYSDATE - 30
ORDER BY attempt_time DESC;


-- --------------------------------------------------
-- QUERY 9: Agency Compliance Scorecard
-- --------------------------------------------------

SELECT 
    ga.agency_id,
    ga.agency_name,
    COUNT(DISTINCT ae.employee_id) as total_employees,
    COUNT(aal.audit_id) as total_access_attempts,
    SUM(CASE WHEN aal.auth_status = 'YES' THEN 1 ELSE 0 END) as authorized_access,
    SUM(CASE WHEN aal.auth_status = 'NO' THEN 1 ELSE 0 END) as denied_access,
    COUNT(DISTINCT pv.violation_id) as total_violations,
    ROUND((SUM(CASE WHEN aal.auth_status = 'YES' THEN 1 ELSE 0 END) / 
           NULLIF(COUNT(aal.audit_id), 0)) * 100, 2) as compliance_rate,
    CASE 
        WHEN ROUND((SUM(CASE WHEN aal.auth_status = 'YES' THEN 1 ELSE 0 END) / 
                    NULLIF(COUNT(aal.audit_id), 0)) * 100, 2) >= 95 THEN '🟢 EXCELLENT'
        WHEN ROUND((SUM(CASE WHEN aal.auth_status = 'YES' THEN 1 ELSE 0 END) / 
                    NULLIF(COUNT(aal.audit_id), 0)) * 100, 2) >= 85 THEN '🟡 GOOD'
        WHEN ROUND((SUM(CASE WHEN aal.auth_status = 'YES' THEN 1 ELSE 0 END) / 
                    NULLIF(COUNT(aal.audit_id), 0)) * 100, 2) >= 70 THEN '🟠 NEEDS IMPROVEMENT'
        ELSE '🔴 CRITICAL'
    END as rating
FROM government_agencies ga
LEFT JOIN agency_employees ae ON ga.agency_id = ae.agency_id
LEFT JOIN access_audit_log aal ON ae.employee_id = aal.employee_id
LEFT JOIN privacy_violations pv ON aal.audit_id = pv.audit_id
GROUP BY ga.agency_id, ga.agency_name
ORDER BY compliance_rate ASC;


-- --------------------------------------------------
-- QUERY 10: Suspicious Activity Detection
-- --------------------------------------------------

SELECT 
    'Bulk Access (>50 attempts in 1 hour)' as pattern_type,
    ae.emp_name,
    ga.agency_name,
    COUNT(*) as access_count,
    MIN(aal.access_time) as first_access,
    MAX(aal.access_time) as last_access
FROM access_audit_log aal
JOIN agency_employees ae ON aal.employee_id = ae.employee_id
JOIN government_agencies ga ON ae.agency_id = ga.agency_id
WHERE aal.access_time >= SYSDATE - 1
GROUP BY ae.employee_id, ae.emp_name, ga.agency_name, 
         TRUNC(aal.access_time, 'HH')
HAVING COUNT(*) > 50

UNION ALL

SELECT 
    'Rapid Failed Attempts (>10 denials in 10 minutes)' as pattern_type,
    ae.emp_name,
    ga.agency_name,
    COUNT(*) as access_count,
    MIN(aal.access_time) as first_access,
    MAX(aal.access_time) as last_access
FROM access_audit_log aal
JOIN agency_employees ae ON aal.employee_id = ae.employee_id
JOIN government_agencies ga ON ae.agency_id = ga.agency_id
WHERE aal.auth_status = 'NO'
  AND aal.access_time >= SYSDATE - 1
GROUP BY ae.employee_id, ae.emp_name, ga.agency_name,
         TRUNC(aal.access_time, 'MI')
HAVING COUNT(*) > 10

ORDER BY first_access DESC;

