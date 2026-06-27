-- ============================================================
-- Banking Customer Onboarding System
-- Schema: Tables, Sequences, Constraints
-- Compatible: Oracle 21c | apex.oracle.com
-- Author: Vishal
-- ============================================================

-- -------------------------------------------------------
-- 1. CUSTOMERS - Master Table
-- -------------------------------------------------------
CREATE TABLE bcos_customers (
    customer_id         NUMBER          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ucic_number         VARCHAR2(20)    UNIQUE,
    first_name          VARCHAR2(100)   NOT NULL,
    last_name           VARCHAR2(100)   NOT NULL,
    date_of_birth       DATE            NOT NULL,
    gender              VARCHAR2(10)    CHECK (gender IN ('MALE','FEMALE','OTHER')),
    mobile_number       VARCHAR2(15)    NOT NULL UNIQUE,
    email_address       VARCHAR2(150)   UNIQUE,
    pan_number          VARCHAR2(10)    UNIQUE,
    aadhar_number       VARCHAR2(12)    UNIQUE,
    nationality         VARCHAR2(50)    DEFAULT 'INDIAN',
    customer_type       VARCHAR2(20)    DEFAULT 'INDIVIDUAL' CHECK (customer_type IN ('INDIVIDUAL','CORPORATE')),
    status              VARCHAR2(20)    DEFAULT 'PENDING' CHECK (status IN ('PENDING','UNDER_REVIEW','APPROVED','REJECTED','DUPLICATE')),
    created_by          VARCHAR2(100),
    created_date        DATE            DEFAULT SYSDATE,
    modified_by         VARCHAR2(100),
    modified_date       DATE
);

-- -------------------------------------------------------
-- 2. KYC VERIFICATION
-- -------------------------------------------------------
CREATE TABLE bcos_kyc_details (
    kyc_id              NUMBER          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id         NUMBER          NOT NULL REFERENCES bcos_customers(customer_id),
    kyc_type            VARCHAR2(30)    CHECK (kyc_type IN ('PAN','AADHAR','PASSPORT','VOTER_ID','DRIVING_LICENSE')),
    kyc_number          VARCHAR2(50)    NOT NULL,
    kyc_status          VARCHAR2(20)    DEFAULT 'PENDING' CHECK (kyc_status IN ('PENDING','VERIFIED','FAILED','EXPIRED')),
    verified_by         VARCHAR2(100),
    verified_date       DATE,
    expiry_date         DATE,
    remarks             VARCHAR2(500),
    created_date        DATE            DEFAULT SYSDATE
);

-- -------------------------------------------------------
-- 3. DOCUMENT UPLOAD
-- -------------------------------------------------------
CREATE TABLE bcos_documents (
    document_id         NUMBER          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id         NUMBER          NOT NULL REFERENCES bcos_customers(customer_id),
    document_type       VARCHAR2(50)    CHECK (document_type IN ('PAN_CARD','AADHAR_CARD','PHOTO','SIGNATURE','BANK_STATEMENT','SALARY_SLIP','PASSPORT','OTHER')),
    document_name       VARCHAR2(200),
    document_blob       BLOB,
    document_mime       VARCHAR2(100),
    file_size           NUMBER,
    upload_status       VARCHAR2(20)    DEFAULT 'UPLOADED' CHECK (upload_status IN ('UPLOADED','VERIFIED','REJECTED')),
    uploaded_by         VARCHAR2(100),
    uploaded_date       DATE            DEFAULT SYSDATE,
    verified_by         VARCHAR2(100),
    verified_date       DATE,
    remarks             VARCHAR2(500)
);

-- -------------------------------------------------------
-- 4. UCIC GENERATION LOG
-- -------------------------------------------------------
CREATE TABLE bcos_ucic_log (
    ucic_log_id         NUMBER          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id         NUMBER          NOT NULL REFERENCES bcos_customers(customer_id),
    ucic_number         VARCHAR2(20)    NOT NULL UNIQUE,
    generated_by        VARCHAR2(100),
    generated_date      DATE            DEFAULT SYSDATE,
    remarks             VARCHAR2(500)
);

-- -------------------------------------------------------
-- 5. DUPLICATE CHECK LOG
-- -------------------------------------------------------
CREATE TABLE bcos_duplicate_check (
    check_id            NUMBER          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id         NUMBER          NOT NULL REFERENCES bcos_customers(customer_id),
    check_type          VARCHAR2(30)    CHECK (check_type IN ('PAN','AADHAR','MOBILE','EMAIL','NAME_DOB')),
    check_value         VARCHAR2(200),
    is_duplicate        VARCHAR2(1)     DEFAULT 'N' CHECK (is_duplicate IN ('Y','N')),
    duplicate_cust_id   NUMBER,
    checked_by          VARCHAR2(100),
    checked_date        DATE            DEFAULT SYSDATE,
    remarks             VARCHAR2(500)
);

-- -------------------------------------------------------
-- 6. APPROVAL WORKFLOW
-- -------------------------------------------------------
CREATE TABLE bcos_approval_workflow (
    workflow_id         NUMBER          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id         NUMBER          NOT NULL REFERENCES bcos_customers(customer_id),
    workflow_stage      VARCHAR2(50)    CHECK (workflow_stage IN ('INITIATED','KYC_VERIFICATION','DOCUMENT_CHECK','DUPLICATE_CHECK','FINAL_APPROVAL','COMPLETED','REJECTED')),
    stage_status        VARCHAR2(20)    DEFAULT 'PENDING' CHECK (stage_status IN ('PENDING','IN_PROGRESS','COMPLETED','REJECTED','ON_HOLD')),
    assigned_to         VARCHAR2(100),
    action_by           VARCHAR2(100),
    action_date         DATE,
    remarks             VARCHAR2(1000),
    created_date        DATE            DEFAULT SYSDATE
);

-- -------------------------------------------------------
-- 7. AUDIT TRAIL
-- -------------------------------------------------------
CREATE TABLE bcos_audit_trail (
    audit_id            NUMBER          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name          VARCHAR2(100),
    record_id           NUMBER,
    action_type         VARCHAR2(20)    CHECK (action_type IN ('INSERT','UPDATE','DELETE','LOGIN','LOGOUT','APPROVE','REJECT')),
    old_value           CLOB,
    new_value           CLOB,
    action_by           VARCHAR2(100),
    action_date         DATE            DEFAULT SYSDATE,
    ip_address          VARCHAR2(50),
    session_id          VARCHAR2(100),
    remarks             VARCHAR2(500)
);

-- -------------------------------------------------------
-- 8. LOOKUP / MASTER DATA
-- -------------------------------------------------------
CREATE TABLE bcos_lookup (
    lookup_id           NUMBER          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lookup_type         VARCHAR2(50)    NOT NULL,
    lookup_code         VARCHAR2(50)    NOT NULL,
    lookup_value        VARCHAR2(200)   NOT NULL,
    display_order       NUMBER          DEFAULT 1,
    is_active           VARCHAR2(1)     DEFAULT 'Y',
    UNIQUE (lookup_type, lookup_code)
);

-- -------------------------------------------------------
-- SEQUENCES for UCIC Generation
-- -------------------------------------------------------
CREATE SEQUENCE bcos_ucic_seq
    START WITH 100001
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- -------------------------------------------------------
-- INDEXES 
-- -------------------------------------------------------
CREATE INDEX idx_bcos_cust_pan       ON bcos_customers(pan_number);
CREATE INDEX idx_bcos_cust_aadhar    ON bcos_customers(aadhar_number);
CREATE INDEX idx_bcos_cust_mobile    ON bcos_customers(mobile_number);
CREATE INDEX idx_bcos_cust_status    ON bcos_customers(status);
CREATE INDEX idx_bcos_kyc_cust       ON bcos_kyc_details(customer_id);
CREATE INDEX idx_bcos_doc_cust       ON bcos_documents(customer_id);
CREATE INDEX idx_bcos_wf_cust        ON bcos_approval_workflow(customer_id);
CREATE INDEX idx_bcos_audit_tbl      ON bcos_audit_trail(table_name, record_id);

COMMIT;
