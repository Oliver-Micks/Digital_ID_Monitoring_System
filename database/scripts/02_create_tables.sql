-- ============================================
-- PHASE 5: TABLE CREATION
-- ============================================

-- 1. CITIZENS TABLE
CREATE TABLE citizens (
    citizen_id   NUMBER(10)    PRIMARY KEY,
    full_name    VARCHAR2(100) NOT NULL,
    dob          DATE,
    phone        VARCHAR2(20)  UNIQUE,
    email        VARCHAR2(100),
    district     VARCHAR2(50),
    status       VARCHAR2(20)  DEFAULT 'ACTIVE'
);

-- 2. GOVERNMENT_AGENCIES TABLE
CREATE TABLE government_agencies (
    agency_id    NUMBER(10)    PRIMARY KEY,
    agency_name  VARCHAR2(100) UNIQUE NOT NULL,
    agency_type  VARCHAR2(50)  NOT NULL,
    auth_level   NUMBER(2)
);

-- 3. AGENCY_EMPLOYEES TABLE
CREATE TABLE agency_employees (
    employee_id  NUMBER(10)    PRIMARY KEY,
    agency_id    NUMBER(10)    NOT NULL REFERENCES government_agencies(agency_id),
    emp_name     VARCHAR2(100) NOT NULL,
    position     VARCHAR2(50),
    username     VARCHAR2(50)  UNIQUE NOT NULL
);

-- 4. ACCESS_PERMISSIONS TABLE (UPDATED with created_at, created_by)
CREATE TABLE access_permissions (
    permission_id NUMBER(10)   PRIMARY KEY,
    agency_id     NUMBER(10)   NOT NULL REFERENCES government_agencies(agency_id),
    data_category VARCHAR2(20) NOT NULL CHECK (data_category IN ('PERSONAL','FINANCIAL','HEALTH','BIOMETRIC')),
    purpose       VARCHAR2(200) NOT NULL,
    created_by    VARCHAR2(50) DEFAULT 'SYSTEM',
    created_at    DATE         DEFAULT SYSDATE,
    expiry_date   DATE         NOT NULL
);

-- 5. ACCESS_AUDIT_LOG TABLE
CREATE TABLE access_audit_log (
    audit_id     NUMBER(12)    PRIMARY KEY,
    employee_id  NUMBER(10)    NOT NULL REFERENCES agency_employees(employee_id),
    citizen_id   NUMBER(10)    NOT NULL REFERENCES citizens(citizen_id),
    access_time  DATE          DEFAULT SYSDATE NOT NULL,
    action       VARCHAR2(50)  NOT NULL,
    auth_status  VARCHAR2(10)  NOT NULL CHECK (auth_status IN ('YES','NO')),
    notes        VARCHAR2(400)
);

--missed some columns :)
ALTER TABLE access_audit_log ADD source_ip VARCHAR2(50);
ALTER TABLE access_audit_log ADD request_purpose VARCHAR2(200);
ALTER TABLE access_audit_log ADD data_category VARCHAR2(50);

-- 6. PRIVACY_VIOLATIONS TABLE
CREATE TABLE privacy_violations (
    violation_id    NUMBER(12)    PRIMARY KEY,
    audit_id        NUMBER(12)    NOT NULL REFERENCES access_audit_log(audit_id),
    violation_type  VARCHAR2(100) NOT NULL,
    severity        VARCHAR2(20)  NOT NULL CHECK (severity IN ('LOW','MEDIUM','HIGH')),
    resolved_status VARCHAR2(20)  DEFAULT 'OPEN'
);

-- 7. CREATE INDEXES FOR PERFORMANCE
CREATE INDEX idx_audit_employee ON access_audit_log(employee_id);
CREATE INDEX idx_audit_citizen ON access_audit_log(citizen_id);
CREATE INDEX idx_audit_time ON access_audit_log(access_time);
CREATE INDEX idx_violation_audit ON privacy_violations(audit_id);
