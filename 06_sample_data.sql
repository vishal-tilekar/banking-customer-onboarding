-- ============================================================
-- Banking Customer Onboarding System
-- Sample / Seed Data
-- Compatible: Oracle 19c
-- ============================================================


INSERT INTO bcos_lookup (lookup_type, lookup_code, lookup_value, display_order) VALUES ('GENDER', 'MALE',   'Male',   1);
INSERT INTO bcos_lookup (lookup_type, lookup_code, lookup_value, display_order) VALUES ('GENDER', 'FEMALE', 'Female', 2);
INSERT INTO bcos_lookup (lookup_type, lookup_code, lookup_value, display_order) VALUES ('GENDER', 'OTHER',  'Other',  3);

INSERT INTO bcos_lookup (lookup_type, lookup_code, lookup_value, display_order) VALUES ('CUSTOMER_TYPE', 'INDIVIDUAL', 'Individual', 1);
INSERT INTO bcos_lookup (lookup_type, lookup_code, lookup_value, display_order) VALUES ('CUSTOMER_TYPE', 'CORPORATE',  'Corporate',  2);

INSERT INTO bcos_lookup (lookup_type, lookup_code, lookup_value, display_order) VALUES ('KYC_TYPE', 'PAN',              'PAN Card',          1);
INSERT INTO bcos_lookup (lookup_type, lookup_code, lookup_value, display_order) VALUES ('KYC_TYPE', 'AADHAR',           'Aadhar Card',       2);
INSERT INTO bcos_lookup (lookup_type, lookup_code, lookup_value, display_order) VALUES ('KYC_TYPE', 'PASSPORT',         'Passport',          3);
INSERT INTO bcos_lookup (lookup_type, lookup_code, lookup_value, display_order) VALUES ('KYC_TYPE', 'VOTER_ID',         'Voter ID',          4);
INSERT INTO bcos_lookup (lookup_type, lookup_code, lookup_value, display_order) VALUES ('KYC_TYPE', 'DRIVING_LICENSE',  'Driving License',   5);

INSERT INTO bcos_lookup (lookup_type, lookup_code, lookup_value, display_order) VALUES ('DOC_TYPE', 'PAN_CARD',      'PAN Card',        1);
INSERT INTO bcos_lookup (lookup_type, lookup_code, lookup_value, display_order) VALUES ('DOC_TYPE', 'AADHAR_CARD',   'Aadhar Card',     2);
INSERT INTO bcos_lookup (lookup_type, lookup_code, lookup_value, display_order) VALUES ('DOC_TYPE', 'PHOTO',         'Photograph',      3);
INSERT INTO bcos_lookup (lookup_type, lookup_code, lookup_value, display_order) VALUES ('DOC_TYPE', 'SIGNATURE',     'Signature',       4);
INSERT INTO bcos_lookup (lookup_type, lookup_code, lookup_value, display_order) VALUES ('DOC_TYPE', 'BANK_STATEMENT','Bank Statement',   5);
INSERT INTO bcos_lookup (lookup_type, lookup_code, lookup_value, display_order) VALUES ('DOC_TYPE', 'SALARY_SLIP',   'Salary Slip',     6);

INSERT INTO bcos_lookup (lookup_type, lookup_code, lookup_value, display_order) VALUES ('STATUS', 'PENDING',      'Pending',      1);
INSERT INTO bcos_lookup (lookup_type, lookup_code, lookup_value, display_order) VALUES ('STATUS', 'UNDER_REVIEW', 'Under Review', 2);
INSERT INTO bcos_lookup (lookup_type, lookup_code, lookup_value, display_order) VALUES ('STATUS', 'APPROVED',     'Approved',     3);
INSERT INTO bcos_lookup (lookup_type, lookup_code, lookup_value, display_order) VALUES ('STATUS', 'REJECTED',     'Rejected',     4);
INSERT INTO bcos_lookup (lookup_type, lookup_code, lookup_value, display_order) VALUES ('STATUS', 'DUPLICATE',    'Duplicate',    5);

COMMIT;

-- -------------------------------------------------------
-- SAMPLE CUSTOMERS (via package for realistic workflow)
-- -------------------------------------------------------
DECLARE
    v_customer_id   NUMBER;
    v_status        VARCHAR2(50);
    v_message       VARCHAR2(500);
BEGIN
    -- Customer 1: PENDING
    bcos_pkg.register_customer(
        p_first_name    => 'Rahul',
        p_last_name     => 'Sharma',
        p_dob           => DATE '1990-05-15',
        p_gender        => 'MALE',
        p_mobile        => '9876543210',
        p_email         => 'rahul.sharma@email.com',
        p_pan           => 'ABCPS1234D',
        p_aadhar        => '123456789012',
        p_customer_type => 'INDIVIDUAL',
        p_customer_id   => v_customer_id,
        p_status        => v_status,
        p_message       => v_message
    );
    DBMS_OUTPUT.PUT_LINE('Customer 1: ' || v_message);

    -- Customer 2: APPROVED (full flow)
    bcos_pkg.register_customer(
        p_first_name    => 'Priya',
        p_last_name     => 'Patil',
        p_dob           => DATE '1988-11-20',
        p_gender        => 'FEMALE',
        p_mobile        => '9123456780',
        p_email         => 'priya.patil@email.com',
        p_pan           => 'BCDPT5678E',
        p_aadhar        => '234567890123',
        p_customer_type => 'INDIVIDUAL',
        p_customer_id   => v_customer_id,
        p_status        => v_status,
        p_message       => v_message
    );
    DBMS_OUTPUT.PUT_LINE('Customer 2: ' || v_message);

    -- Customer 3: REJECTED
    bcos_pkg.register_customer(
        p_first_name    => 'Amit',
        p_last_name     => 'Desai',
        p_dob           => DATE '1975-03-08',
        p_gender        => 'MALE',
        p_mobile        => '9988776655',
        p_email         => 'amit.desai@email.com',
        p_pan           => 'CDEPA9012F',
        p_aadhar        => '345678901234',
        p_customer_type => 'INDIVIDUAL',
        p_customer_id   => v_customer_id,
        p_status        => v_status,
        p_message       => v_message
    );
    DBMS_OUTPUT.PUT_LINE('Customer 3: ' || v_message);

    -- Customer 4: CORPORATE
    bcos_pkg.register_customer(
        p_first_name    => 'Infosys',
        p_last_name     => 'Ltd',
        p_dob           => DATE '2000-01-01',
        p_gender        => 'OTHER',
        p_mobile        => '9001122334',
        p_email         => 'accounts@infosys-demo.com',
        p_pan           => 'DEFPB3456G',
        p_aadhar        => '456789012345',
        p_customer_type => 'CORPORATE',
        p_customer_id   => v_customer_id,
        p_status        => v_status,
        p_message       => v_message
    );
    DBMS_OUTPUT.PUT_LINE('Customer 4: ' || v_message);

    -- Customer 5: UNDER_REVIEW
    bcos_pkg.register_customer(
        p_first_name    => 'Sneha',
        p_last_name     => 'Kulkarni',
        p_dob           => DATE '1995-07-22',
        p_gender        => 'FEMALE',
        p_mobile        => '9876501234',
        p_email         => 'sneha.kulkarni@email.com',
        p_pan           => 'EFGPC7890H',
        p_aadhar        => '567890123456',
        p_customer_type => 'INDIVIDUAL',
        p_customer_id   => v_customer_id,
        p_status        => v_status,
        p_message       => v_message
    );
    DBMS_OUTPUT.PUT_LINE('Customer 5: ' || v_message);

    COMMIT;
END;
/
