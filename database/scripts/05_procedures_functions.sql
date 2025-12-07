-- ==================================================
-- PHASE 6: PL/SQL PROCEDURES, FUNCTIONS, PACKAGES
-- Connect as: digital_id_user
-- IT INCLUDES:
--   -  Procedures 
--   - Functions 
--   - Cursors (explicit)
--   - Packages
--   - Exception Handling
-- ==================================================

SET SERVEROUTPUT ON;

-- --------------------------------------------------
-- STEP 0: CREATE SEQUENCES 
-- --------------------------------------------------

CREATE SEQUENCE seq_audit_id START WITH 2000 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_violation_id START WITH 100 INCREMENT BY 1 NOCACHE;


-- --------------------------------------------------
-- A. FUNCTIONS 
-- --------------------------------------------------

-- FUNCTION 1: Get District Population Count (Calculation)
-- Purpose: BI analytics - calculate citizen density by district
CREATE OR REPLACE FUNCTION fn_get_district_count(p_district VARCHAR2) 
RETURN NUMBER IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count 
    FROM citizens 
    WHERE district = p_district;
    
    RETURN v_count;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in fn_get_district_count: ' || SQLERRM);
        RETURN -1;
END fn_get_district_count;
/

-- FUNCTION 2: Check Permission Validity (Validation)
-- Purpose: Returns TRUE if agency has active, non-expired permission for data category
CREATE OR REPLACE FUNCTION fn_has_permission(
    p_agency_id NUMBER, 
    p_category VARCHAR2
) RETURN BOOLEAN IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count 
    FROM access_permissions 
    WHERE agency_id = p_agency_id 
      AND data_category = p_category
      AND expiry_date >= SYSDATE;
    
    RETURN (v_count > 0);
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END fn_has_permission;
/

-- FUNCTION 3: Get Employee's Agency Name (Lookup)
-- Purpose: Quick lookup for reports and audit logs
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

-- FUNCTION 4: Calculate Compliance Rate (Calculation for BI)
-- Purpose: Returns percentage of authorized vs total access attempts for an agency
CREATE OR REPLACE FUNCTION fn_get_agency_compliance(p_agency_id NUMBER) 
RETURN NUMBER IS
    v_total NUMBER;
    v_authorized NUMBER;
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

-- FUNCTION 5: Check if Time is After Hours (Validation)
-- Purpose: Returns TRUE if timestamp is between 8 PM - 6 AM (suspicious access time)
CREATE OR REPLACE FUNCTION fn_is_after_hours(p_timestamp DATE) 
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

-- PROCEDURE 1: Register New Citizen (IN parameters + DML: INSERT)
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
    DBMS_OUTPUT.PUT_LINE('✅ Citizen ' || p_id || ' (' || p_name || ') registered in ' || p_district);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        DBMS_OUTPUT.PUT_LINE('❌ Error: Citizen ID ' || p_id || ' already exists.');
        ROLLBACK;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ Error registering citizen: ' || SQLERRM);
        ROLLBACK;
END sp_register_citizen;
/

-- PROCEDURE 2: Validate and Log Access Attempt (IN + OUT parameters)
-- Purpose: Check permission, log attempt, return authorization status
CREATE OR REPLACE PROCEDURE sp_validate_access (
    p_employee_id IN NUMBER,
    p_citizen_id IN NUMBER,
    p_data_category IN VARCHAR2,
    p_action IN VARCHAR2,
    p_authorized OUT VARCHAR2,  -- OUT parameter: Returns 'YES' or 'NO'
    p_message OUT VARCHAR2      -- OUT parameter: Returns status message
) AS
    v_agency_id NUMBER;
    v_has_permission BOOLEAN;
BEGIN
    -- Get employee's agency
    SELECT agency_id INTO v_agency_id
    FROM agency_employees
    WHERE employee_id = p_employee_id;
    
    -- Check if agency has permission for this data category
    v_has_permission := fn_has_permission(v_agency_id, p_data_category);
    
    IF v_has_permission THEN
        p_authorized := 'YES';
        p_message := 'Access granted for ' || p_data_category || ' data.';
    ELSE
        p_authorized := 'NO';
        p_message := 'DENIED: No valid permission for ' || p_data_category || ' data.';
    END IF;
    
    -- Log the access attempt
    INSERT INTO access_audit_log (
        audit_id, employee_id, citizen_id, access_time, 
        action, auth_status, notes
    ) VALUES (
        seq_audit_id.NEXTVAL, p_employee_id, p_citizen_id, SYSDATE,
        p_action, p_authorized, p_message
    );
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✅ Access attempt logged: ' || p_message);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_authorized := 'NO';
        p_message := 'ERROR: Employee or citizen not found.';
        ROLLBACK;
    WHEN OTHERS THEN
        p_authorized := 'NO';
        p_message := 'ERROR: ' || SQLERRM;
        ROLLBACK;
END sp_validate_access;
/

-- PROCEDURE 3: Update Citizen District (IN OUT parameter)
-- Purpose: Update citizen's district and return new district count
CREATE OR REPLACE PROCEDURE sp_update_citizen_district (
    p_citizen_id IN NUMBER,
    p_new_district IN OUT VARCHAR2  -- IN OUT: Receives district, returns it capitalized
) AS
    v_old_district VARCHAR2(50);
BEGIN
    -- Get current district
    SELECT district INTO v_old_district
    FROM citizens
    WHERE citizen_id = p_citizen_id;
    
    -- Capitalize the new district name
    p_new_district := UPPER(p_new_district);
    
    -- Update citizen's district
    UPDATE citizens
    SET district = p_new_district
    WHERE citizen_id = p_citizen_id;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✅ Citizen ' || p_citizen_id || ' moved from ' || 
                         v_old_district || ' to ' || p_new_district);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('❌ Error: Citizen ID ' || p_citizen_id || ' not found.');
        ROLLBACK;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ Error updating district: ' || SQLERRM);
        ROLLBACK;
END sp_update_citizen_district;
/

-- PROCEDURE 4: Revoke Expired Permissions (DML: UPDATE + Cursor)
-- Purpose: Batch update to deactivate expired permissions
CREATE OR REPLACE PROCEDURE sp_revoke_expired_permissions AS
    v_count NUMBER := 0;
    
    -- Explicit Cursor 
    CURSOR c_expired IS
        SELECT permission_id, agency_id, data_category, expiry_date
        FROM access_permissions
        WHERE expiry_date < SYSDATE;
    
    v_rec c_expired%ROWTYPE;
BEGIN
    OPEN c_expired;
    LOOP
        FETCH c_expired INTO v_rec;
        EXIT WHEN c_expired%NOTFOUND;
        
        -- Delete expired permission (instead of updating non-existent status column)
        DELETE FROM access_permissions
        WHERE permission_id = v_rec.permission_id;
        
        v_count := v_count + 1;
        
        DBMS_OUTPUT.PUT_LINE('🗑️  Removed expired permission ' || v_rec.permission_id || 
                             ' (Agency: ' || v_rec.agency_id || 
                             ', Category: ' || v_rec.data_category || ')');
    END LOOP;
    CLOSE c_expired;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✅ Total expired permissions removed: ' || v_count);
    
EXCEPTION
    WHEN OTHERS THEN
        IF c_expired%ISOPEN THEN
            CLOSE c_expired;
        END IF;
        DBMS_OUTPUT.PUT_LINE('❌ Error revoking permissions: ' || SQLERRM);
        ROLLBACK;
END sp_revoke_expired_permissions;
/

-- PROCEDURE 5: Generate Active Agencies Report (Explicit Cursor)
-- Purpose: Display all agencies with their employees
CREATE OR REPLACE PROCEDURE sp_active_agencies_report AS
    CURSOR c_agencies IS
        SELECT agency_id, agency_name, agency_type, auth_level
        FROM government_agencies
        ORDER BY agency_name;
    
    v_agency c_agencies%ROWTYPE;
    v_emp_count NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('     ACTIVE AGENCIES REPORT');
    DBMS_OUTPUT.PUT_LINE('========================================');
    
    OPEN c_agencies;
    LOOP
        FETCH c_agencies INTO v_agency;
        EXIT WHEN c_agencies%NOTFOUND;
        
        -- Count employees for this agency
        SELECT COUNT(*) INTO v_emp_count
        FROM agency_employees
        WHERE agency_id = v_agency.agency_id;
        
        DBMS_OUTPUT.PUT_LINE('Agency: ' || v_agency.agency_name || 
                             ' | Type: ' || v_agency.agency_type || 
                             ' | Auth Level: ' || v_agency.auth_level ||
                             ' | Employees: ' || v_emp_count);
    END LOOP;
    CLOSE c_agencies;
    
    DBMS_OUTPUT.PUT_LINE('========================================');
    
EXCEPTION
    WHEN OTHERS THEN
        IF c_agencies%ISOPEN THEN
            CLOSE c_agencies;
        END IF;
        DBMS_OUTPUT.PUT_LINE('❌ Error generating report: ' || SQLERRM);
END sp_active_agencies_report;
/


-- --------------------------------------------------
-- C. PACKAGE 
-- --------------------------------------------------

-- PACKAGE SPECIFICATION: Public interface
CREATE OR REPLACE PACKAGE pkg_audit_tools AS
    -- Public function: Calculate agency compliance
    FUNCTION fn_get_compliance(p_agency_id NUMBER) RETURN NUMBER;
    
    -- Public procedure: Clean up old audit logs (older than 1 year)
    PROCEDURE sp_archive_old_logs(p_days_old IN NUMBER DEFAULT 365);
    
    -- Public procedure: Get top N violators
    PROCEDURE sp_get_top_violators(p_top_n IN NUMBER DEFAULT 5);
END pkg_audit_tools;
/

-- PACKAGE BODY: Implementation
CREATE OR REPLACE PACKAGE BODY pkg_audit_tools AS

    -- Function: Calculate compliance (wrapper around standalone function)
    FUNCTION fn_get_compliance(p_agency_id NUMBER) RETURN NUMBER IS
    BEGIN
        RETURN fn_get_agency_compliance(p_agency_id);
    END fn_get_compliance;

    -- Procedure: Archive old audit logs
    PROCEDURE sp_archive_old_logs(p_days_old IN NUMBER DEFAULT 365) IS
        v_cutoff_date DATE;
        v_deleted NUMBER;
    BEGIN
        v_cutoff_date := SYSDATE - p_days_old;
        
        DELETE FROM access_audit_log
        WHERE access_time < v_cutoff_date;
        
        v_deleted := SQL%ROWCOUNT;
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('✅ Archived ' || v_deleted || ' old audit log entries.');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('❌ Error archiving logs: ' || SQLERRM);
            ROLLBACK;
    END sp_archive_old_logs;
    
    -- Procedure: Get top violators
    PROCEDURE sp_get_top_violators(p_top_n IN NUMBER DEFAULT 5) IS
        CURSOR c_violators IS
            SELECT ae.emp_name, ga.agency_name, COUNT(*) as violation_count
            FROM privacy_violations pv
            JOIN access_audit_log aal ON pv.audit_id = aal.audit_id
            JOIN agency_employees ae ON aal.employee_id = ae.employee_id
            JOIN government_agencies ga ON ae.agency_id = ga.agency_id
            GROUP BY ae.emp_name, ga.agency_name
            ORDER BY violation_count DESC
            FETCH FIRST p_top_n ROWS ONLY;
        
        v_rec c_violators%ROWTYPE;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('========================================');
        DBMS_OUTPUT.PUT_LINE('     TOP ' || p_top_n || ' VIOLATORS');
        DBMS_OUTPUT.PUT_LINE('========================================');
        
        OPEN c_violators;
        LOOP
            FETCH c_violators INTO v_rec;
            EXIT WHEN c_violators%NOTFOUND;
            
            DBMS_OUTPUT.PUT_LINE('Employee: ' || v_rec.emp_name || 
                                 ' | Agency: ' || v_rec.agency_name ||
                                 ' | Violations: ' || v_rec.violation_count);
        END LOOP;
        CLOSE c_violators;
        
    EXCEPTION
        WHEN OTHERS THEN
            IF c_violators%ISOPEN THEN
                CLOSE c_violators;
            END IF;
            DBMS_OUTPUT.PUT_LINE('❌ Error: ' || SQLERRM);
    END sp_get_top_violators;

END pkg_audit_tools;
/


-- --------------------------------------------------
-- D. TEST SECTION 
-- --------------------------------------------------


-- Test Function 1: District count
DECLARE
    v_count NUMBER;
BEGIN
    v_count := fn_get_district_count('Gasabo');
    DBMS_OUTPUT.PUT_LINE('TEST: Citizens in Gasabo = ' || v_count);
END;
/

-- Test Procedure 2: Validate access (with OUT parameters)
DECLARE
    v_auth VARCHAR2(10);
    v_msg VARCHAR2(200);
BEGIN
    sp_validate_access(101, 1, 'FINANCIAL', 'VIEW', v_auth, v_msg);
    DBMS_OUTPUT.PUT_LINE('TEST: Authorization = ' || v_auth);
    DBMS_OUTPUT.PUT_LINE('TEST: Message = ' || v_msg);
END;
/

-- Test Procedure 3: Update district (with IN OUT parameter)
DECLARE
    v_district VARCHAR2(50) := 'nyarugenge';
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST: District before = ' || v_district);
    sp_update_citizen_district(1, v_district);
    DBMS_OUTPUT.PUT_LINE('TEST: District after = ' || v_district);
END;
/

-- Test Procedure 5: Active agencies report
BEGIN
    sp_active_agencies_report;
END;
/

-- Test Package function
DECLARE
    v_compliance NUMBER;
BEGIN
    v_compliance := pkg_audit_tools.fn_get_compliance(1);
    DBMS_OUTPUT.PUT_LINE('TEST: Agency 1 compliance = ' || v_compliance || '%');
END;
/
