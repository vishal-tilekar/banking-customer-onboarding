-- ============================================================
-- Banking Customer Onboarding System
-- REST APIs using Oracle REST Data Services (ORDS)
-- Compatible: Oracle 21c + apex.oracle.com
-- ============================================================

-- -------------------------------------------------------
-- ENABLE ORDS for Schema 
-- -------------------------------------------------------
BEGIN
    ORDS.ENABLE_SCHEMA(
        p_enabled             => TRUE,
        p_schema              => 'YOUR_SCHEMA_NAME',  -- Replace with your schema
        p_url_mapping_type    => 'BASE_PATH',
        p_url_mapping_pattern => 'bcos',
        p_auto_rest_auth      => FALSE
    );
    COMMIT;
END;
/


-- -------------------------------------------------------
-- MODULE: Customer Onboarding API
-- Base Path: /bcos/api/
-- -------------------------------------------------------
BEGIN
    ORDS.DEFINE_MODULE(
        p_module_name    => 'bcos.customer.api',
        p_base_path      => '/bcos/api/',
        p_items_per_page => 25,
        p_status         => 'PUBLISHED',
        p_comments       => 'Banking Customer Onboarding REST APIs'
    );
    COMMIT;
END;
/



-- API 1: POST /bcos/api/customer/register
-- Register a new customer

BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'bcos.customer.api',
        p_pattern        => 'customer/register',
        p_priority       => 0,
        p_etag_type      => 'HASH',
        p_comments       => 'Register new customer'
    );

    ORDS.DEFINE_HANDLER(
        p_module_name    => 'bcos.customer.api',
        p_pattern        => 'customer/register',
        p_method         => 'POST',
        p_source_type    => ORDS.source_type_plsql,
        p_source         => '
DECLARE
    v_customer_id   NUMBER;
    v_status        VARCHAR2(50);
    v_message       VARCHAR2(500);
    v_body          CLOB;
    v_json          JSON_OBJECT_T;
BEGIN
    v_body := :body_text;
    v_json := JSON_OBJECT_T.PARSE(v_body);

    bcos_pkg.register_customer(
        p_first_name    => v_json.get_string(''first_name''),
        p_last_name     => v_json.get_string(''last_name''),
        p_dob           => TO_DATE(v_json.get_string(''date_of_birth''), ''YYYY-MM-DD''),
        p_gender        => v_json.get_string(''gender''),
        p_mobile        => v_json.get_string(''mobile_number''),
        p_email         => v_json.get_string(''email_address''),
        p_pan           => v_json.get_string(''pan_number''),
        p_aadhar        => v_json.get_string(''aadhar_number''),
        p_customer_type => NVL(v_json.get_string(''customer_type''), ''INDIVIDUAL''),
        p_customer_id   => v_customer_id,
        p_status        => v_status,
        p_message       => v_message
    );

    :status := CASE WHEN v_status = ''SUCCESS'' THEN 201 ELSE 400 END;
    HTP.P(JSON_OBJECT(
        ''status''       VALUE v_status,
        ''customer_id''  VALUE v_customer_id,
        ''message''      VALUE v_message
    ));
EXCEPTION
    WHEN OTHERS THEN
        :status := 500;
        HTP.P(JSON_OBJECT(
            ''status''   VALUE ''ERROR'',
            ''message''  VALUE SQLERRM
        ));
END;',
        p_comments       => 'POST: Register new customer'
    );
    COMMIT;
END;
/


-- -------------------------------------------------------
-- API 2: GET /bcos/api/customer/:id
-- Get customer details by ID
-- -------------------------------------------------------
BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'bcos.customer.api',
        p_pattern        => 'customer/:id',
        p_priority       => 0,
        p_etag_type      => 'HASH',
        p_comments       => 'Get customer by ID'
    );

    ORDS.DEFINE_HANDLER(
        p_module_name    => 'bcos.customer.api',
        p_pattern        => 'customer/:id',
        p_method         => 'GET',
        p_source_type    => ORDS.source_type_collection_feed,
        p_source         => '
SELECT
    c.customer_id,
    c.ucic_number,
    c.first_name,
    c.last_name,
    TO_CHAR(c.date_of_birth, ''YYYY-MM-DD'') AS date_of_birth,
    c.gender,
    c.mobile_number,
    c.email_address,
    c.pan_number,
    c.aadhar_number,
    c.customer_type,
    c.status,
    c.created_by,
    TO_CHAR(c.created_date, ''YYYY-MM-DD HH24:MI:SS'') AS created_date,
    (SELECT COUNT(1) FROM bcos_documents d WHERE d.customer_id = c.customer_id) AS total_documents,
    (SELECT COUNT(1) FROM bcos_kyc_details k WHERE k.customer_id = c.customer_id AND k.kyc_status = ''VERIFIED'') AS verified_kyc_count
FROM bcos_customers c
WHERE c.customer_id = :id',
        p_comments       => 'GET: Customer details by ID'
    );
    COMMIT;
END;
/


-- -------------------------------------------------------
-- API 3: GET /bcos/api/customer/list
-- Get all customers with filter support
-- -------------------------------------------------------
BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'bcos.customer.api',
        p_pattern        => 'customer/list',
        p_priority       => 0,
        p_etag_type      => 'HASH',
        p_comments       => 'List all customers'
    );

    ORDS.DEFINE_HANDLER(
        p_module_name    => 'bcos.customer.api',
        p_pattern        => 'customer/list',
        p_method         => 'GET',
        p_source_type    => ORDS.source_type_collection_feed,
        p_source         => '
SELECT
    customer_id,
    ucic_number,
    first_name || '' '' || last_name  AS full_name,
    mobile_number,
    email_address,
    pan_number,
    customer_type,
    status,
    TO_CHAR(created_date, ''YYYY-MM-DD'')  AS registration_date
FROM bcos_customers
WHERE (:status IS NULL OR status = :status)
ORDER BY created_date DESC',
        p_comments       => 'GET: List all customers'
    );
    COMMIT;
END;
/


-- -------------------------------------------------------
-- API 4: PUT /bcos/api/customer/workflow/:id
-- Approve / Reject / Hold customer application
-- -------------------------------------------------------
BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'bcos.customer.api',
        p_pattern        => 'customer/workflow/:id',
        p_priority       => 0,
        p_etag_type      => 'HASH',
        p_comments       => 'Update workflow status'
    );

    ORDS.DEFINE_HANDLER(
        p_module_name    => 'bcos.customer.api',
        p_pattern        => 'customer/workflow/:id',
        p_method         => 'PUT',
        p_source_type    => ORDS.source_type_plsql,
        p_source         => '
DECLARE
    v_status    VARCHAR2(50);
    v_message   VARCHAR2(500);
    v_body      CLOB;
    v_json      JSON_OBJECT_T;
BEGIN
    v_body := :body_text;
    v_json := JSON_OBJECT_T.PARSE(v_body);

    bcos_pkg.process_workflow(
        p_customer_id   => :id,
        p_action        => UPPER(v_json.get_string(''action'')),
        p_remarks       => v_json.get_string(''remarks''),
        p_status        => v_status,
        p_message       => v_message
    );

    :status := CASE WHEN v_status = ''SUCCESS'' THEN 200 ELSE 400 END;
    HTP.P(JSON_OBJECT(
        ''status''   VALUE v_status,
        ''message''  VALUE v_message
    ));
EXCEPTION
    WHEN OTHERS THEN
        :status := 500;
        HTP.P(JSON_OBJECT(''status'' VALUE ''ERROR'', ''message'' VALUE SQLERRM));
END;',
        p_comments       => 'PUT: Approve/Reject/Hold workflow'
    );
    COMMIT;
END;
/


-- -------------------------------------------------------
-- API 5: GET /bcos/api/dashboard
-- Dashboard summary stats
-- -------------------------------------------------------
BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'bcos.customer.api',
        p_pattern        => 'dashboard',
        p_priority       => 0,
        p_etag_type      => 'HASH',
        p_comments       => 'Dashboard summary'
    );

    ORDS.DEFINE_HANDLER(
        p_module_name    => 'bcos.customer.api',
        p_pattern        => 'dashboard',
        p_method         => 'GET',
        p_source_type    => ORDS.source_type_collection_feed,
        p_source         => '
SELECT
    COUNT(*)                                                    AS total_customers,
    SUM(CASE WHEN status = ''PENDING''      THEN 1 ELSE 0 END) AS pending,
    SUM(CASE WHEN status = ''UNDER_REVIEW'' THEN 1 ELSE 0 END) AS under_review,
    SUM(CASE WHEN status = ''APPROVED''     THEN 1 ELSE 0 END) AS approved,
    SUM(CASE WHEN status = ''REJECTED''     THEN 1 ELSE 0 END) AS rejected,
    SUM(CASE WHEN status = ''DUPLICATE''    THEN 1 ELSE 0 END) AS duplicates,
    SUM(CASE WHEN TRUNC(created_date) = TRUNC(SYSDATE) THEN 1 ELSE 0 END) AS today_registrations
FROM bcos_customers',
        p_comments       => 'GET: Dashboard summary stats'
    );
    COMMIT;
END;
/
