-- ==================================================
-- ANALYTICS QUERIES
-- Advanced analytical queries for business intelligence
-- These queries demonstrate complex SQL techniques:
--   - Window functions
--   - Aggregations
--   - Subqueries
--   - Complex joins
-- ==================================================

SET LINESIZE 200
SET PAGESIZE 100
COL agency_name FORMAT A30
COL emp_name FORMAT A25
COL citizen_name FORMAT A25
COL action FORMAT A20
COL data_category FORMAT A15


-- --------------------------------------------------
-- QUERY 1: Top 10 Most Active Employees
-- --------------------------------------------------
-- Top 10 Most Active Employees 

SELECT 
    employee_rank,
    emp_name,
    agency_name,
    total_access_attempts,
    authorized_access,
    unauthorized_access,
    ROUND((authorized_access / total_access_attempts) * 100, 2) as compliance_rate
FROM (
    SELECT 
        ae.emp_name,
        ga.agency_name,
        COUNT(*) as total_access_attempts,
        SUM(CASE WHEN aal.auth_status = 'YES' THEN 1 ELSE 0 END) as authorized_access,
        SUM(CASE WHEN aal.auth_status = 'NO' THEN 1 ELSE 0 END) as unauthorized_access,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) as employee_rank
    FROM access_audit_log aal
    JOIN agency_employees ae ON aal.employee_id = ae.employee_id
    JOIN government_agencies ga ON ae.agency_id = ga.agency_id
    GROUP BY ae.emp_name, ga.agency_name
)
WHERE employee_rank <= 10
ORDER BY employee_rank;


-- --------------------------------------------------
-- QUERY 2: Agency Performance Scorecard
-- --------------------------------------------------
-- Agency Performance Scorecard 

SELECT 
    agency_name,
    agency_type,
    total_employees,
    total_permissions,
    total_access_attempts,
    authorized_attempts,
    denied_attempts,
    ROUND((authorized_attempts / NULLIF(total_access_attempts, 0)) * 100, 2) as compliance_rate,
    violation_count,
    CASE 
        WHEN violation_count > 100 THEN 'HIGH RISK'
        WHEN violation_count BETWEEN 50 AND 100 THEN 'MEDIUM RISK'
        WHEN violation_count BETWEEN 1 AND 49 THEN 'LOW RISK'
        ELSE 'NO VIOLATIONS'
    END as risk_level
FROM (
    SELECT 
        ga.agency_id,
        ga.agency_name,
        ga.agency_type,
        COUNT(DISTINCT ae.employee_id) as total_employees,
        COUNT(DISTINCT ap.permission_id) as total_permissions,
        COUNT(aal.audit_id) as total_access_attempts,
        SUM(CASE WHEN aal.auth_status = 'YES' THEN 1 ELSE 0 END) as authorized_attempts,
        SUM(CASE WHEN aal.auth_status = 'NO' THEN 1 ELSE 0 END) as denied_attempts,
        COUNT(DISTINCT pv.violation_id) as violation_count
    FROM government_agencies ga
    LEFT JOIN agency_employees ae ON ga.agency_id = ae.agency_id
    LEFT JOIN access_permissions ap ON ga.agency_id = ap.agency_id
    LEFT JOIN access_audit_log aal ON ae.employee_id = aal.employee_id
    LEFT JOIN privacy_violations pv ON aal.audit_id = pv.audit_id
    GROUP BY ga.agency_id, ga.agency_name, ga.agency_type
)
ORDER BY compliance_rate ASC, violation_count DESC;


-- --------------------------------------------------
-- QUERY 3: Data Category Access Distribution
-- --------------------------------------------------
-- Data Category Access Distribution 

SELECT 
    data_category,
    total_requests,
    authorized_requests,
    denied_requests,
    ROUND((authorized_requests / total_requests) * 100, 2) as authorization_rate,
    unique_agencies_requesting,
    unique_employees_requesting
FROM (
    SELECT 
        aal.data_category,
        COUNT(*) as total_requests,
        SUM(CASE WHEN aal.auth_status = 'YES' THEN 1 ELSE 0 END) as authorized_requests,
        SUM(CASE WHEN aal.auth_status = 'NO' THEN 1 ELSE 0 END) as denied_requests,
        COUNT(DISTINCT ae.agency_id) as unique_agencies_requesting,
        COUNT(DISTINCT aal.employee_id) as unique_employees_requesting
    FROM access_audit_log aal
    JOIN agency_employees ae ON aal.employee_id = ae.employee_id
    WHERE aal.data_category IS NOT NULL
    GROUP BY aal.data_category
)
ORDER BY total_requests DESC;


-- --------------------------------------------------
-- QUERY 4: Monthly Access Trends with Year-over-Year Comparison
-- --------------------------------------------------
-- Monthly Access Trends (Last 6 Months) 

SELECT 
    access_month,
    total_access,
    authorized,
    denied,
    prev_month_access,
    CASE 
        WHEN prev_month_access IS NULL THEN 'N/A (First Month)'
        WHEN total_access > prev_month_access THEN '↑ +' || (total_access - prev_month_access) || ' (' || ROUND(((total_access - prev_month_access) / prev_month_access) * 100, 1) || '%)'
        WHEN total_access < prev_month_access THEN '↓ -' || (prev_month_access - total_access) || ' (' || ROUND(((prev_month_access - total_access) / prev_month_access) * 100, 1) || '%)'
        ELSE '→ No Change'
    END as month_over_month_trend
FROM (
    SELECT 
        TO_CHAR(access_time, 'YYYY-MM') as access_month,
        COUNT(*) as total_access,
        SUM(CASE WHEN auth_status = 'YES' THEN 1 ELSE 0 END) as authorized,
        SUM(CASE WHEN auth_status = 'NO' THEN 1 ELSE 0 END) as denied,
        LAG(COUNT(*)) OVER (ORDER BY TO_CHAR(access_time, 'YYYY-MM')) as prev_month_access
    FROM access_audit_log
    GROUP BY TO_CHAR(access_time, 'YYYY-MM')
    ORDER BY access_month DESC
)
WHERE ROWNUM <= 6
ORDER BY access_month DESC;


-- --------------------------------------------------
-- QUERY 5: Citizen Privacy Impact Report
-- --------------------------------------------------
-- Most Frequently Accessed Citizens 

SELECT 
    access_rank,
    citizen_name,
    citizen_district,
    total_access_count,
    unique_agencies,
    unique_employees,
    last_access_date,
    ROUND(SYSDATE - last_access_date) as days_since_last_access,
    CASE 
        WHEN total_access_count > 100 THEN 'VERY HIGH'
        WHEN total_access_count BETWEEN 50 AND 100 THEN 'HIGH'
        WHEN total_access_count BETWEEN 20 AND 49 THEN 'MODERATE'
        ELSE 'LOW'
    END as exposure_level
FROM (
    SELECT 
        c.full_name as citizen_name,
        c.district as citizen_district,
        COUNT(aal.audit_id) as total_access_count,
        COUNT(DISTINCT ae.agency_id) as unique_agencies,
        COUNT(DISTINCT aal.employee_id) as unique_employees,
        MAX(aal.access_time) as last_access_date,
        ROW_NUMBER() OVER (ORDER BY COUNT(aal.audit_id) DESC) as access_rank
    FROM citizens c
    LEFT JOIN access_audit_log aal ON c.citizen_id = aal.citizen_id
    LEFT JOIN agency_employees ae ON aal.employee_id = ae.employee_id
    GROUP BY c.citizen_id, c.full_name, c.district
)
WHERE access_rank <= 15
ORDER BY access_rank;


-- --------------------------------------------------
-- QUERY 6: After-Hours Access Analysis
-- --------------------------------------------------
-- After-Hours Access Patterns 

SELECT 
    hour_of_day,
    access_count,
    authorized_count,
    denied_count,
    CASE 
        WHEN hour_of_day BETWEEN 0 AND 5 THEN 'Night (12AM-6AM)'
        WHEN hour_of_day BETWEEN 6 AND 8 THEN 'Early Morning (6AM-9AM)'
        WHEN hour_of_day BETWEEN 9 AND 17 THEN 'Business Hours (9AM-6PM)'
        WHEN hour_of_day BETWEEN 18 AND 19 THEN 'Evening (6PM-8PM)'
        ELSE 'After Hours (8PM-12AM)'
    END as time_category,
    ROUND((access_count / SUM(access_count) OVER ()) * 100, 2) as pct_of_total_access
FROM (
    SELECT 
        TO_NUMBER(TO_CHAR(access_time, 'HH24')) as hour_of_day,
        COUNT(*) as access_count,
        SUM(CASE WHEN auth_status = 'YES' THEN 1 ELSE 0 END) as authorized_count,
        SUM(CASE WHEN auth_status = 'NO' THEN 1 ELSE 0 END) as denied_count
    FROM access_audit_log
    GROUP BY TO_NUMBER(TO_CHAR(access_time, 'HH24'))
)
ORDER BY hour_of_day;


-- --------------------------------------------------
-- QUERY 7: Violation Severity Distribution
-- --------------------------------------------------
-- Privacy Violations by Severity 

SELECT 
    severity,
    total_violations,
    open_violations,
    investigating_violations,
    resolved_violations,
    ROUND((resolved_violations / total_violations) * 100, 2) as resolution_rate,
    avg_days_to_resolve
FROM (
    SELECT 
        severity,
        COUNT(*) as total_violations,
        SUM(CASE WHEN resolved_status = 'OPEN' THEN 1 ELSE 0 END) as open_violations,
        SUM(CASE WHEN resolved_status = 'INVESTIGATING' THEN 1 ELSE 0 END) as investigating_violations,
        SUM(CASE WHEN resolved_status = 'RESOLVED' THEN 1 ELSE 0 END) as resolved_violations,
        ROUND(AVG(CASE WHEN resolved_status = 'RESOLVED' THEN SYSDATE - created_at END), 1) as avg_days_to_resolve
    FROM privacy_violations
    GROUP BY severity
)
ORDER BY 
    CASE severity 
        WHEN 'HIGH' THEN 1 
        WHEN 'MEDIUM' THEN 2 
        WHEN 'LOW' THEN 3 
    END;


-- --------------------------------------------------
-- QUERY 8: Permission Expiry Alert Report
-- --------------------------------------------------
-- Permissions Expiring in Next 30 Days 

SELECT 
    agency_name,
    data_category,
    purpose,
    expiry_date,
    ROUND(expiry_date - SYSDATE) as days_until_expiry,
    CASE 
        WHEN expiry_date < SYSDATE THEN '🔴 EXPIRED'
        WHEN expiry_date - SYSDATE <= 7 THEN '🟠 URGENT (< 7 days)'
        WHEN expiry_date - SYSDATE <= 30 THEN '🟡 WARNING (< 30 days)'
        ELSE '🟢 ACTIVE'
    END as status
FROM (
    SELECT 
        ga.agency_name,
        ap.data_category,
        ap.purpose,
        ap.expiry_date
    FROM access_permissions ap
    JOIN government_agencies ga ON ap.agency_id = ga.agency_id
    WHERE ap.expiry_date <= SYSDATE + 30
)
ORDER BY days_until_expiry;


-- --------------------------------------------------
-- QUERY 9: Employee Access Ranking Within Agency
-- --------------------------------------------------
-- Top 3 Employees per Agency 

SELECT 
    agency_name,
    employee_rank,
    emp_name,
    total_access_attempts,
    compliance_rate
FROM (
    SELECT 
        ga.agency_name,
        ae.emp_name,
        COUNT(aal.audit_id) as total_access_attempts,
        ROUND((SUM(CASE WHEN aal.auth_status = 'YES' THEN 1 ELSE 0 END) / COUNT(aal.audit_id)) * 100, 2) as compliance_rate,
        ROW_NUMBER() OVER (PARTITION BY ga.agency_id ORDER BY COUNT(aal.audit_id) DESC) as employee_rank
    FROM government_agencies ga
    JOIN agency_employees ae ON ga.agency_id = ae.agency_id
    LEFT JOIN access_audit_log aal ON ae.employee_id = aal.employee_id
    GROUP BY ga.agency_id, ga.agency_name, ae.emp_name
)
WHERE employee_rank <= 3
ORDER BY agency_name, employee_rank;


-- --------------------------------------------------
-- QUERY 10: District-Level Access Statistics
-- --------------------------------------------------
--  Citizen Data Access by District 

SELECT 
    district,
    total_citizens,
    citizens_accessed,
    ROUND((citizens_accessed / total_citizens) * 100, 2) as pct_citizens_accessed,
    total_access_attempts,
    ROUND(total_access_attempts / NULLIF(citizens_accessed, 0), 1) as avg_access_per_citizen,
    RANK() OVER (ORDER BY total_access_attempts DESC) as district_rank
FROM (
    SELECT 
        c.district,
        COUNT(DISTINCT c.citizen_id) as total_citizens,
        COUNT(DISTINCT CASE WHEN aal.audit_id IS NOT NULL THEN c.citizen_id END) as citizens_accessed,
        COUNT(aal.audit_id) as total_access_attempts
    FROM citizens c
    LEFT JOIN access_audit_log aal ON c.citizen_id = aal.citizen_id
    GROUP BY c.district
)
ORDER BY total_access_attempts DESC;


