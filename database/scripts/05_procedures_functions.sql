-- ============================================================
-- PHASE 6: PL/SQL PROCEDURES, FUNCTIONS, PACKAGES
-- Connect as: digital_id_user
-- This file:
--  - creates helper sequences if missing
--  - functions: validations, lookups
--  - procedures: register, validate access, revoke expired permissions, reports
--  - package: audit tools 
-- ============================================================

SET SERVEROUTPUT ON

-- Create sequences if they do not exist (safe to run multiple times)
BEGIN
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_audit_id START WITH 1000 INCREMENT BY 1';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_violation_id START WITH 1 INCREMENT BY 1';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- Create audit_archive table - used by archive procedure 
BEGIN
  EXECUTE IMMEDIATE '
    CREATE TABLE audit_archive AS
    SELECT * FROM access_audit_log WHERE 1=0
  ';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- --------------------------------------------------
-- A. FUNCTIONS
-- --------------------------------------------------

CREATE OR REPLACE FUNCTION fn_get_district_count(p_district VARCHAR2)
RETURN NUMBER IS
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM citizens WHERE district = p_district;
  RETURN v_count;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 0;
  WHEN OTHERS THEN
    RETURN -1;
END fn_get_district_count;
/

CREATE OR REPLACE FUNCTION fn_has_permission(p_agency_id NUMBER, p_category VARCHAR2)
RETURN BOOLEAN IS
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count
    FROM access_permissions
   WHERE agency_id = p_agency_id
     AND data_category = UPPER(p_category)
     AND expiry_date >= SYSDATE;
  RETURN (v_count > 0);
EXCEPTION
  WHEN OTHERS THEN
    RETURN FALSE;
END fn_has_permission;
/

CREATE OR REPLACE FUNCTION fn_get_employee_agency(p_emp_id NUMBER)
RETURN VARCHAR2 IS
  v_agency_name VARCHAR2(100);
BEGIN
  SELECT ga.agency_name INTO v_agency_name
  FROM government_agencies ga
  JOIN agency_employees ae ON ga.agency_id = ae.agency_id
  WHERE ae.employee_id = p_emp_id;
  RETURN v_agency_name;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 'UNKNOWN_AGENCY';
  WHEN OTHERS THEN
    RETURN 'ERROR';
END fn_get_employee_agency;
/

CREATE OR REPLACE FUNCTION fn_get_agency_compliance(p_agency_id NUMBER)
RETURN NUMBER IS
  v_total NUMBER := 0;
  v_authorized NUMBER := 0;
BEGIN
  SELECT COUNT(*), SUM(CASE WHEN auth_status = 'YES' THEN 1 ELSE 0 END)
    INTO v_total, v_authorized
    FROM access_audit_log aal
    JOIN agency_employees ae ON aal.employee_id = ae.employee_id
   WHERE ae.agency_id = p_agency_id;

  IF v_total = 0 THEN
    RETURN 100;
  END IF;

  RETURN ROUND((v_authorized / v_total) * 100, 2);
EXCEPTION
  WHEN OTHERS THEN
    RETURN 0;
END fn_get_agency_compliance;
/

CREATE OR REPLACE FUNCTION fn_is_after_hours(p_timestamp TIMESTAMP)
RETURN BOOLEAN IS
  v_hour NUMBER;
BEGIN
  v_hour := TO_NUMBER(TO_CHAR(p_timestamp, 'HH24'));
  RETURN (v_hour >= 20 OR v_hour < 6);
EXCEPTION
  WHEN OTHERS THEN
    RETURN FALSE;
END fn_is_after_hours;
/

-- --------------------------------------------------
-- B. PROCEDURES
-- --------------------------------------------------

CREATE OR REPLACE PROCEDURE sp_register_citizen (
  p_id IN NUMBER,
  p_name IN VARCHAR2,
  p_dob IN DATE,
  p_district IN VARCHAR2
) AS
BEGIN
  INSERT INTO citizens (citizen_id, full_name, dob, district, status)
  VALUES (p_id, UPPER(p_name), p_dob, p_district, 'ACTIVE');

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Citizen ' || p_id || ' registered.');
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    DBMS_OUTPUT.PUT_LINE('Error: Citizen ID ' || p_id || ' already exists.');
    ROLLBACK;
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error registering citizen: ' || SQLERRM);
    ROLLBACK;
END sp_register_citizen;
/

CREATE OR REPLACE PROCEDURE sp_validate_access (
  p_employee_id IN NUMBER,
  p_citizen_id IN NUMBER,
  p_data_category IN VARCHAR2,
  p_action IN VARCHAR2,
  p_authorized OUT VARCHAR2,
  p_message OUT VARCHAR2,
  p_source_ip IN VARCHAR2 DEFAULT NULL
) AS
  v_agency_id NUMBER;
  v_has_permission BOOLEAN;
  v_audit_id NUMBER;
BEGIN
  -- get agency
  SELECT agency_id INTO v_agency_id
  FROM agency_employees
  WHERE employee_id = p_employee_id;

  -- check permission
  v_has_permission := fn_has_permission(v_agency_id, p_data_category);

  IF v_has_permission THEN
    p_authorized := 'YES';
    p_message := 'Access granted';
  ELSE
    p_authorized := 'NO';
    p_message := 'DENIED: No valid permission';
  END IF;

  -- generate audit_id using sequence
  v_audit_id := seq_audit_id.NEXTVAL;

  INSERT INTO access_audit_log (
    audit_id,
    employee_id,
    citizen_id,
    access_time,
    action,
    data_category,
    auth_status,
    request_purpose,
    source_ip,
    notes
  ) VALUES (
    v_audit_id,
    p_employee_id,
    p_citizen_id,
    SYSTIMESTAMP,
    p_action,
    UPPER(p_data_category),
    p_authorized,
    NULL,
    p_source_ip,
    p_message
  );

  COMMIT;

  DBMS_OUTPUT.PUT_LINE('Access attempt logged. AUTH=' || p_authorized || ' audit_id=' || v_audit_id);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    p_authorized := 'NO';
    p_message := 'ERROR: Employee or citizen not found';
    ROLLBACK;
  WHEN OTHERS THEN
    p_authorized := 'NO';
    p_message := 'ERROR: ' || SQLERRM;
    ROLLBACK;
END sp_validate_access;
/

CREATE OR REPLACE PROCEDURE sp_update_citizen_district (
  p_citizen_id IN NUMBER,
  p_new_district IN OUT VARCHAR2
) AS
  v_old_district VARCHAR2(50);
BEGIN
  SELECT district INTO v_old_district FROM citizens WHERE citizen_id = p_citizen_id;

  p_new_district := UPPER(p_new_district);

  UPDATE citizens
  SET district = p_new_district
  WHERE citizen_id = p_citizen_id;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Citizen ' || p_citizen_id || ' district updated.');
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Error: Citizen ID not found.');
    ROLLBACK;
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error updating district: ' || SQLERRM);
    ROLLBACK;
END sp_update_citizen_district;
/

CREATE OR REPLACE PROCEDURE sp_revoke_expired_permissions AS
  CURSOR c_expired IS
    SELECT permission_id FROM access_permissions WHERE expiry_date < SYSDATE;
  v_id access_permissions.permission_id%TYPE;
  v_count NUMBER := 0;
BEGIN
  OPEN c_expired;
  LOOP
    FETCH c_expired INTO v_id;
    EXIT WHEN c_expired%NOTFOUND;

    DELETE FROM access_permissions WHERE permission_id = v_id;
    v_count := v_count + 1;
  END LOOP;
  CLOSE c_expired;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Expired permissions removed: ' || v_count);
EXCEPTION
  WHEN OTHERS THEN
    IF c_expired%ISOPEN THEN CLOSE c_expired; END IF;
    DBMS_OUTPUT.PUT_LINE('Error revoking permissions: ' || SQLERRM);
    ROLLBACK;
END sp_revoke_expired_permissions;
/

CREATE OR REPLACE PROCEDURE sp_active_agencies_report AS
  CURSOR c_agencies IS
    SELECT agency_id, agency_name, agency_type, auth_level FROM government_agencies ORDER BY agency_name;
  v_agency c_agencies%ROWTYPE;
  v_emp_count NUMBER;
BEGIN
  FOR v_agency IN c_agencies LOOP
    SELECT COUNT(*) INTO v_emp_count FROM agency_employees WHERE agency_id = v_agency.agency_id;
    DBMS_OUTPUT.PUT_LINE('Agency: ' || v_agency.agency_name || ' | Employees: ' || v_emp_count);
  END LOOP;
END sp_active_agencies_report;
/

-- --------------------------------------------------
-- C. WINDOW / ANALYTIC procedures 
-- --------------------------------------------------

CREATE OR REPLACE PROCEDURE sp_rank_agencies_by_violations AS
BEGIN
  FOR rec IN (
    SELECT ga.agency_name, COUNT(pv.violation_id) total_violations,
           RANK() OVER (ORDER BY COUNT(pv.violation_id) DESC) violation_rank
    FROM government_agencies ga
    LEFT JOIN agency_employees ae ON ga.agency_id = ae.agency_id
    LEFT JOIN access_audit_log aal ON ae.employee_id = aal.employee_id
    LEFT JOIN privacy_violations pv ON aal.audit_id = pv.audit_id
    GROUP BY ga.agency_name
    ORDER BY total_violations DESC
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Rank ' || rec.violation_rank || ': ' || rec.agency_name || ' | Violations: ' || rec.total_violations);
  END LOOP;
END sp_rank_agencies_by_violations;
/

CREATE OR REPLACE PROCEDURE sp_monthly_access_trends AS
BEGIN
  FOR rec IN (
    SELECT access_month, access_count, prev_month_count,
           CASE WHEN prev_month_count IS NULL THEN 'N/A'
                WHEN access_count > prev_month_count THEN 'UP'
                WHEN access_count < prev_month_count THEN 'DOWN'
                ELSE 'NO CHANGE' END as trend
    FROM (
      SELECT TO_CHAR(access_time, 'YYYY-MM') access_month,
             COUNT(*) access_count,
             LAG(COUNT(*)) OVER (ORDER BY TO_CHAR(access_time,'YYYY-MM')) prev_month_count
      FROM access_audit_log
      GROUP BY TO_CHAR(access_time, 'YYYY-MM')
      ORDER BY access_month DESC
    )
    WHERE ROWNUM <= 6
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Month: ' || rec.access_month || ' | Access: ' || rec.access_count || ' | Trend: ' || rec.trend);
  END LOOP;
END sp_monthly_access_trends;
/

CREATE OR REPLACE PROCEDURE sp_top_employees_by_agency AS
BEGIN
  FOR rec IN (
    SELECT agency_name, emp_name, access_count, employee_rank
    FROM (
      SELECT ga.agency_name, ae.emp_name, COUNT(aal.audit_id) access_count,
             ROW_NUMBER() OVER (PARTITION BY ga.agency_id ORDER BY COUNT(aal.audit_id) DESC) employee_rank
      FROM government_agencies ga
      JOIN agency_employees ae ON ga.agency_id = ae.agency_id
      LEFT JOIN access_audit_log aal ON ae.employee_id = aal.employee_id
      GROUP BY ga.agency_id, ga.agency_name, ae.emp_name
    )
    WHERE employee_rank <= 3
    ORDER BY agency_name, employee_rank
  ) LOOP
    DBMS_OUTPUT.PUT_LINE(rec.agency_name || ' | #' || rec.employee_rank || ': ' || rec.emp_name || ' (' || rec.access_count || ')');
  END LOOP;
END sp_top_employees_by_agency;
/

CREATE OR REPLACE PROCEDURE sp_employee_access_cumulative(p_employee_id IN NUMBER) AS
BEGIN
  FOR rec IN (
    SELECT TO_CHAR(access_time,'YYYY-MM-DD HH24:MI') access_timestamp, action, auth_status,
           SUM(1) OVER (ORDER BY access_time) running_total
    FROM access_audit_log
    WHERE employee_id = p_employee_id
    ORDER BY access_time DESC
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Time: ' || rec.access_timestamp || ' | Action: ' || rec.action || ' | Status: ' || rec.auth_status || ' | Running: ' || rec.running_total);
  END LOOP;
END sp_employee_access_cumulative;
/

-- --------------------------------------------------
-- D. PACKAGE: pkg_audit_tools
-- --------------------------------------------------

CREATE OR REPLACE PACKAGE pkg_audit_tools AS
  FUNCTION fn_get_compliance(p_agency_id NUMBER) RETURN NUMBER;
  PROCEDURE sp_archive_old_logs(p_days_old IN NUMBER DEFAULT 365);
  PROCEDURE sp_get_top_violators(p_top_n IN NUMBER DEFAULT 5);
END pkg_audit_tools;
/

CREATE OR REPLACE PACKAGE BODY pkg_audit_tools AS

  FUNCTION fn_get_compliance(p_agency_id NUMBER) RETURN NUMBER IS
  BEGIN
    RETURN fn_get_agency_compliance(p_agency_id);
  END fn_get_compliance;

  PROCEDURE sp_archive_old_logs(p_days_old IN NUMBER DEFAULT 365) IS
    v_cutoff DATE := SYSDATE - p_days_old;
    v_copied NUMBER := 0;
  BEGIN
    -- copy matching rows to audit_archive (preserve immutable original)
    INSERT INTO audit_archive
    SELECT * FROM access_audit_log WHERE access_time < v_cutoff;

    v_copied := SQL%ROWCOUNT;
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Archived (copied) ' || v_copied || ' audit rows to audit_archive.');
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error archiving logs: ' || SQLERRM);
      ROLLBACK;
  END sp_archive_old_logs;

  PROCEDURE sp_get_top_violators(p_top_n IN NUMBER DEFAULT 5) IS
    CURSOR c_violators IS
      SELECT * FROM (
        SELECT ae.emp_name, ga.agency_name, COUNT(*) violation_count
        FROM privacy_violations pv
        JOIN access_audit_log aal ON pv.audit_id = aal.audit_id
        JOIN agency_employees ae ON aal.employee_id = ae.employee_id
        JOIN government_agencies ga ON ae.agency_id = ga.agency_id
        GROUP BY ae.emp_name, ga.agency_name
        ORDER BY COUNT(*) DESC
      ) WHERE ROWNUM <= p_top_n;
    v_rec c_violators%ROWTYPE;
  BEGIN
    FOR v_rec IN c_violators LOOP
      DBMS_OUTPUT.PUT_LINE('Employee: ' || v_rec.emp_name || ' | Agency: ' || v_rec.agency_name || ' | Violations: ' || v_rec.violation_count);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error fetching top violators: ' || SQLERRM);
  END sp_get_top_violators;

END pkg_audit_tools;
/
--solve some issues on audit_archieve table
ALTER TABLE audit_archive ADD source_ip VARCHAR2(50);
ALTER TABLE audit_archive ADD request_purpose VARCHAR2(200);
ALTER TABLE audit_archive ADD data_category VARCHAR2(50);