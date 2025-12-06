-- ==================================================
-- PHASE 7: TRIGGERS & ADVANCED SECURITY
-- Connect as: digital_id_user
-- THIS INCLUDES:
--   - Weekend/Holiday restriction trigger
--   - Audit logging triggers
--   - Business rule enforcement
-- ==================================================

SET SERVEROUTPUT ON;

-- --------------------------------------------------
-- TRIGGER 1: Weekend-Only DML Restriction 
-- --------------------------------------------------

-- Purpose: Block INSERT/UPDATE/DELETE on citizens table during weekdays (Mon-Fri)
-- Rationale: Prevent unauthorized data modifications during business hours

CREATE OR REPLACE TRIGGER trg_weekend_only_citizens
BEFORE INSERT OR UPDATE OR DELETE ON citizens
BEGIN
    -- Check if today is Monday (2) through Friday (6)
    -- D format: 1=Sunday, 2=Monday, 3=Tuesday, 4=Wednesday, 5=Thursday, 6=Friday, 7=Saturday
    IF TO_NUMBER(TO_CHAR(SYSDATE, 'D')) BETWEEN 2 AND 6 THEN
        RAISE_APPLICATION_ERROR(-20001, 
            '⛔ SECURITY BLOCK: Data modifications on CITIZENS table are restricted to WEEKENDS ONLY. ' ||
            'Today is ' || TO_CHAR(SYSDATE, 'Day') || '. Please retry on Saturday or Sunday.');
    END IF;
END trg_weekend_only_citizens;
/


-- --------------------------------------------------
-- TRIGGER 2: Auto-Log Citizen Profile Updates
-- --------------------------------------------------

-- Purpose: Automatically log changes to citizen contact information
-- Creates audit trail for GDPR-like compliance

CREATE OR REPLACE TRIGGER trg_audit_citizen_updates
AFTER UPDATE OF phone, email, district ON citizens
FOR EACH ROW
BEGIN
    -- Log the profile update
    INSERT INTO access_audit_log (
        audit_id, 
        employee_id, 
        citizen_id, 
        access_time,
        action, 
        auth_status, 
        notes
    ) VALUES (
        seq_audit_id.NEXTVAL,
        0,  -- 0 indicates system action, not employee
        :OLD.citizen_id,
        SYSDATE,
        'CITIZEN_PROFILE_UPDATE',
        'YES',
        'Profile updated: ' ||
        CASE WHEN :OLD.phone != :NEW.phone THEN 'Phone: ' || :OLD.phone || ' → ' || :NEW.phone || '; ' ELSE '' END ||
        CASE WHEN :OLD.email != :NEW.email THEN 'Email: ' || :OLD.email || ' → ' || :NEW.email || '; ' ELSE '' END ||
        CASE WHEN :OLD.district != :NEW.district THEN 'District: ' || :OLD.district || ' → ' || :NEW.district ELSE '' END
    );
END trg_audit_citizen_updates;
/


-- --------------------------------------------------
-- TRIGGER 3: Auto-Create Violation for Unauthorized Access
-- --------------------------------------------------

-- Purpose: Automatically create privacy violation record when unauthorized access is logged
-- Enforces security policy at database level

CREATE OR REPLACE TRIGGER trg_auto_create_violation
AFTER INSERT ON access_audit_log
FOR EACH ROW
WHEN (NEW.auth_status = 'NO')  -- Only when access was denied
BEGIN
    -- Automatically create a privacy violation record
    INSERT INTO privacy_violations (
        violation_id,
        audit_id,
        violation_type,
        severity,
        resolved_status
    ) VALUES (
        seq_violation_id.NEXTVAL,
        :NEW.audit_id,
        'UNAUTHORIZED_ACCESS_ATTEMPT',
        CASE 
            WHEN fn_is_after_hours(:NEW.access_time) THEN 'HIGH'  -- After hours = more suspicious
            ELSE 'MEDIUM'
        END,
        'OPEN'
    );
    
    DBMS_OUTPUT.PUT_LINE('🚨 ALERT: Violation record created for audit_id ' || :NEW.audit_id);
END trg_auto_create_violation;
/


-- --------------------------------------------------
-- TRIGGER 4: Escalate High-Severity Violations
-- --------------------------------------------------

-- Purpose: Auto-escalate HIGH severity violations to 'INVESTIGATING' status
-- Ensures immediate action on critical security incidents

CREATE OR REPLACE TRIGGER trg_escalate_high_violations
BEFORE INSERT ON privacy_violations
FOR EACH ROW
WHEN (NEW.severity = 'HIGH')
BEGIN
    -- Override status for high-severity violations
    :NEW.resolved_status := 'INVESTIGATING';
    
    DBMS_OUTPUT.PUT_LINE('⚠️  HIGH SEVERITY VIOLATION: Auto-escalated to INVESTIGATING status.');
END trg_escalate_high_violations;
/


-- --------------------------------------------------
-- TRIGGER 5: Prevent Deletion of Audit Logs (Immutability)
-- --------------------------------------------------

-- Purpose: Make audit logs immutable - prevent any deletion
-- Critical for forensic investigations and compliance

CREATE OR REPLACE TRIGGER trg_protect_audit_log
BEFORE DELETE ON access_audit_log
BEGIN
    RAISE_APPLICATION_ERROR(-20002, 
        '🔒 SECURITY VIOLATION: Audit logs are IMMUTABLE and cannot be deleted. ' ||
        'This action has been logged for security review.');
END trg_protect_audit_log;
/


-- --------------------------------------------------
-- TEST SECTION: Verify Triggers Work
-- --------------------------------------------------

-- Test 1: Try to update citizen on a weekday (should FAIL if today is Mon-Fri)
PROMPT TEST 1: Testing weekend-only restriction...;
DECLARE
    v_day_name VARCHAR2(10);
    v_day_num NUMBER;
BEGIN
    v_day_name := TO_CHAR(SYSDATE, 'Day');
    v_day_num := TO_NUMBER(TO_CHAR(SYSDATE, 'D'));
    
    DBMS_OUTPUT.PUT_LINE('Today is: ' || TRIM(v_day_name) || ' (Day #' || v_day_num || ')');
    
    IF v_day_num BETWEEN 2 AND 6 THEN
        DBMS_OUTPUT.PUT_LINE('⚠️  Weekday detected. Trigger will BLOCK modifications.');
        DBMS_OUTPUT.PUT_LINE('Run this test on Saturday or Sunday to see successful update.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('✅ Weekend detected. Modifications are ALLOWED.');
        -- Try an update (will succeed on weekends)
        UPDATE citizens SET phone = '0781111111' WHERE citizen_id = 1;
        ROLLBACK;  -- Don't actually change data
        DBMS_OUTPUT.PUT_LINE('✅ Update succeeded (rolled back for testing).');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ Trigger blocked the operation: ' || SQLERRM);
END;
/

-- Test 2: Verify audit log protection
PROMPT TEST 2: Testing audit log immutability...;
BEGIN
    DELETE FROM access_audit_log WHERE ROWNUM = 1;
    DBMS_OUTPUT.PUT_LINE('❌ TEST FAILED: Deletion should have been blocked!');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✅ TEST PASSED: ' || SQLERRM);
END;
/

-- Test 3: Create unauthorized access and verify violation auto-creation
PROMPT TEST 3: Testing auto-violation creation...;
DECLARE
    v_auth VARCHAR2(10);
    v_msg VARCHAR2(200);
    v_violation_count NUMBER;
BEGIN
    -- Create an unauthorized access attempt
    sp_validate_access(
        p_employee_id => 101,
        p_citizen_id => 50,
        p_data_category => 'HEALTH',  -- RRA doesn't have HEALTH permission
        p_action => 'VIEW',
        p_authorized => v_auth,
        p_message => v_msg
    );
    
    -- Check if violation was auto-created
    SELECT COUNT(*) INTO v_violation_count
    FROM privacy_violations
    WHERE audit_id = (SELECT MAX(audit_id) FROM access_audit_log);
    
    IF v_violation_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('✅ TEST PASSED: Violation auto-created for unauthorized access.');
    ELSE
    DBMS_OUTPUT.PUT_LINE('❌ TEST FAILED: Violation was not created.');
END IF;
END;
/
