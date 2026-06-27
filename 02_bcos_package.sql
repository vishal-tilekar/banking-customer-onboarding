

-- -------------------------------------------------------
-- PACKAGE SPECIFICATION
-- -------------------------------------------------------
CREATE OR REPLACE PACKAGE bcos_pkg AS

    -- Customer Registration
    PROCEDURE register_customer (
        p_first_name        IN  VARCHAR2,
        p_last_name         IN  VARCHAR2,
        p_dob               IN  DATE,
        p_gender            IN  VARCHAR2,
        p_mobile            IN  VARCHAR2,
        p_email             IN  VARCHAR2,
        p_pan               IN  VARCHAR2,
        p_aadhar            IN  VARCHAR2,
        p_customer_type     IN  VARCHAR2 DEFAULT 'INDIVIDUAL',
        p_customer_id       OUT NUMBER,
        p_status            OUT VARCHAR2,
        p_message           OUT VARCHAR2
    );

    -- Duplicate Check
    FUNCTION check_duplicate (
        p_pan               IN  VARCHAR2,
        p_aadhar            IN  VARCHAR2,
        p_mobile            IN  VARCHAR2,
        p_email             IN  VARCHAR2,
        p_customer_id       IN  NUMBER DEFAULT NULL
    ) RETURN VARCHAR2;

    -- UCIC Generation
    FUNCTION generate_ucic (
        p_customer_id       IN  NUMBER
    ) RETURN VARCHAR2;

    -- KYC Verification
    PROCEDURE verify_kyc (
        p_customer_id       IN  NUMBER,
        p_kyc_type          IN  VARCHAR2,
        p_kyc_number        IN  VARCHAR2,
        p_status            OUT VARCHAR2,
        p_message           OUT VARCHAR2
    );

    -- Approval Workflow
    PROCEDURE process_workflow (
        p_customer_id       IN  NUMBER,
        p_action            IN  VARCHAR2,   -- APPROVE / REJECT / HOLD
        p_remarks           IN  VARCHAR2,
        p_status            OUT VARCHAR2,
        p_message           OUT VARCHAR2
    );

    -- Audit Trail
    PROCEDURE log_audit (
        p_table_name        IN  VARCHAR2,
        p_record_id         IN  NUMBER,
        p_action_type       IN  VARCHAR2,
        p_old_value         IN  CLOB DEFAULT NULL,
        p_new_value         IN  CLOB DEFAULT NULL,
        p_remarks           IN  VARCHAR2 DEFAULT NULL
    );

    -- Dashboard Summary
    FUNCTION get_dashboard_summary RETURN SYS_REFCURSOR;

END bcos_pkg;
/



CREATE OR REPLACE PACKAGE BODY bcos_pkg AS

  
    PROCEDURE register_customer (
        p_first_name        IN  VARCHAR2,
        p_last_name         IN  VARCHAR2,
        p_dob               IN  DATE,
        p_gender            IN  VARCHAR2,
        p_mobile            IN  VARCHAR2,
        p_email             IN  VARCHAR2,
        p_pan               IN  VARCHAR2,
        p_aadhar            IN  VARCHAR2,
        p_customer_type     IN  VARCHAR2 DEFAULT 'INDIVIDUAL',
        p_customer_id       OUT NUMBER,
        p_status            OUT VARCHAR2,
        p_message           OUT VARCHAR2
    ) AS
        v_duplicate     VARCHAR2(10);
        v_new_id        NUMBER;
    BEGIN
        -- Step 1: Duplicate Check
        v_duplicate := check_duplicate(
            p_pan         => p_pan,
            p_aadhar      => p_aadhar,
            p_mobile      => p_mobile,
            p_email       => p_email
        );

        IF v_duplicate = 'Y' THEN
            p_status  := 'DUPLICATE';
            p_message := 'Customer already exists with same PAN/Aadhar/Mobile/Email.';
            RETURN;
        END IF;

        -- Step 2: Insert Customer
        INSERT INTO bcos_customers (
            first_name, last_name, date_of_birth, gender,
            mobile_number, email_address, pan_number, aadhar_number,
            customer_type, status, created_by, created_date
        ) VALUES (
            UPPER(p_first_name), UPPER(p_last_name), p_dob, p_gender,
            p_mobile, LOWER(p_email), UPPER(p_pan), p_aadhar,
            p_customer_type, 'PENDING', NVL(V('APP_USER'), USER), SYSDATE
        ) RETURNING customer_id INTO v_new_id;

        -- Step 3: Initiate Workflow
        INSERT INTO bcos_approval_workflow (
            customer_id, workflow_stage, stage_status,
            assigned_to, created_date
        ) VALUES (
            v_new_id, 'INITIATED', 'COMPLETED',
            NVL(V('APP_USER'), USER), SYSDATE
        );

        -- Step 4: KYC Stage
        INSERT INTO bcos_approval_workflow (
            customer_id, workflow_stage, stage_status, created_date
        ) VALUES (
            v_new_id, 'KYC_VERIFICATION', 'PENDING', SYSDATE
        );

        -- Step 5: Audit
        log_audit(
            p_table_name  => 'BCOS_CUSTOMERS',
            p_record_id   => v_new_id,
            p_action_type => 'INSERT',
            p_new_value   => TO_CLOB('Customer Registered: ' || UPPER(p_first_name) || ' ' || UPPER(p_last_name)),
            p_remarks     => 'New Customer Registration'
        );

        p_customer_id := v_new_id;
        p_status      := 'SUCCESS';
        p_message     := 'Customer registered successfully. Customer ID: ' || v_new_id;

        COMMIT;

    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            ROLLBACK;
            p_status  := 'ERROR';
            p_message := 'Duplicate entry: PAN/Aadhar/Mobile/Email already registered.';
        WHEN OTHERS THEN
            ROLLBACK;
            p_status  := 'ERROR';
            p_message := 'Error in registration: ' || SQLERRM;
            log_audit('BCOS_CUSTOMERS', NULL, 'INSERT', NULL, NULL, SQLERRM);
    END register_customer;



    FUNCTION check_duplicate (
        p_pan               IN  VARCHAR2,
        p_aadhar            IN  VARCHAR2,
        p_mobile            IN  VARCHAR2,
        p_email             IN  VARCHAR2,
        p_customer_id       IN  NUMBER DEFAULT NULL
    ) RETURN VARCHAR2 AS
        v_count     NUMBER := 0;
    BEGIN
        SELECT COUNT(1)
        INTO   v_count
        FROM   bcos_customers
        WHERE  (
                   (p_pan    IS NOT NULL AND pan_number      = UPPER(p_pan))
                OR (p_aadhar IS NOT NULL AND aadhar_number   = p_aadhar)
                OR (p_mobile IS NOT NULL AND mobile_number   = p_mobile)
                OR (p_email  IS NOT NULL AND email_address   = LOWER(p_email))
               )
        AND    (p_customer_id IS NULL OR customer_id <> p_customer_id)
        AND    status NOT IN ('REJECTED');

        IF v_count > 0 THEN
            RETURN 'Y';
        ELSE
            RETURN 'N';
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'N';
    END check_duplicate;


    
    -- GENERATE UCIC
    FUNCTION generate_ucic (
        p_customer_id   IN  NUMBER
    ) RETURN VARCHAR2 AS
        v_ucic      VARCHAR2(20);
        v_seq       NUMBER;
        v_exists    NUMBER;
    BEGIN
        -- Check if UCIC already exists
        SELECT COUNT(1) INTO v_exists
        FROM   bcos_customers
        WHERE  customer_id  = p_customer_id
        AND    ucic_number IS NOT NULL;

        IF v_exists > 0 THEN
            SELECT ucic_number INTO v_ucic
            FROM   bcos_customers
            WHERE  customer_id = p_customer_id;
            RETURN v_ucic;
        END IF;

        -- Generate new UCIC: UCIC + YEAR + SEQUENCE
        SELECT bcos_ucic_seq.NEXTVAL INTO v_seq FROM DUAL;
        v_ucic := 'UCIC' || TO_CHAR(SYSDATE, 'YY') || LPAD(v_seq, 6, '0');

        -- Update Customer
        UPDATE bcos_customers
        SET    ucic_number   = v_ucic,
               modified_by   = NVL(V('APP_USER'), USER),
               modified_date  = SYSDATE
        WHERE  customer_id   = p_customer_id;

        -- Log UCIC
        INSERT INTO bcos_ucic_log (
            customer_id, ucic_number, generated_by, generated_date
        ) VALUES (
            p_customer_id, v_ucic, NVL(V('APP_USER'), USER), SYSDATE
        );

        -- Audit
        log_audit('BCOS_CUSTOMERS', p_customer_id, 'UPDATE',
                  NULL, TO_CLOB('UCIC Generated: ' || v_ucic), 'UCIC Generation');

        COMMIT;
        RETURN v_ucic;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RETURN NULL;
    END generate_ucic;


    -- KYC VERIFICATION
    PROCEDURE verify_kyc (
        p_customer_id   IN  NUMBER,
        p_kyc_type      IN  VARCHAR2,
        p_kyc_number    IN  VARCHAR2,
        p_status        OUT VARCHAR2,
        p_message       OUT VARCHAR2
    ) AS
        v_kyc_id    NUMBER;
    BEGIN
        -- Insert KYC Record
        INSERT INTO bcos_kyc_details (
            customer_id, kyc_type, kyc_number,
            kyc_status, verified_by, verified_date
        ) VALUES (
            p_customer_id, p_kyc_type, p_kyc_number,
            'VERIFIED', NVL(V('APP_USER'), USER), SYSDATE
        ) RETURNING kyc_id INTO v_kyc_id;

        -- Update Workflow Stage
        UPDATE bcos_approval_workflow
        SET    stage_status  = 'COMPLETED',
               action_by     = NVL(V('APP_USER'), USER),
               action_date   = SYSDATE
        WHERE  customer_id   = p_customer_id
        AND    workflow_stage = 'KYC_VERIFICATION'
        AND    stage_status   = 'PENDING';

        -- Move to Document Check Stage
        INSERT INTO bcos_approval_workflow (
            customer_id, workflow_stage, stage_status, created_date
        ) VALUES (
            p_customer_id, 'DOCUMENT_CHECK', 'PENDING', SYSDATE
        );

        -- Audit
        log_audit('BCOS_KYC_DETAILS', v_kyc_id, 'INSERT',
                  NULL, TO_CLOB(p_kyc_type || ': ' || p_kyc_number), 'KYC Verified');

        p_status  := 'SUCCESS';
        p_message := 'KYC verified successfully.';
        COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            p_status  := 'ERROR';
            p_message := 'KYC Verification failed: ' || SQLERRM;
    END verify_kyc;


    -- APPROVAL WORKFLOW
    PROCEDURE process_workflow (
        p_customer_id   IN  NUMBER,
        p_action        IN  VARCHAR2,
        p_remarks       IN  VARCHAR2,
        p_status        OUT VARCHAR2,
        p_message       OUT VARCHAR2
    ) AS
        v_ucic      VARCHAR2(20);
        v_stage     VARCHAR2(50);
    BEGIN
        -- Get current pending stage
        SELECT workflow_stage INTO v_stage
        FROM   bcos_approval_workflow
        WHERE  customer_id   = p_customer_id
        AND    stage_status   = 'PENDING'
        AND    ROWNUM         = 1
        ORDER  BY workflow_id;

        IF p_action = 'APPROVE' THEN
            -- Complete current stage
            UPDATE bcos_approval_workflow
            SET    stage_status  = 'COMPLETED',
                   action_by     = NVL(V('APP_USER'), USER),
                   action_date   = SYSDATE,
                   remarks       = p_remarks
            WHERE  customer_id   = p_customer_id
            AND    workflow_stage = v_stage;

            -- Final Approval
            IF v_stage = 'FINAL_APPROVAL' THEN
                UPDATE bcos_customers
                SET    status        = 'APPROVED',
                       modified_by   = NVL(V('APP_USER'), USER),
                       modified_date  = SYSDATE
                WHERE  customer_id   = p_customer_id;

                -- Generate UCIC
                v_ucic := generate_ucic(p_customer_id);

                INSERT INTO bcos_approval_workflow (
                    customer_id, workflow_stage, stage_status,
                    action_by, action_date, remarks
                ) VALUES (
                    p_customer_id, 'COMPLETED', 'COMPLETED',
                    NVL(V('APP_USER'), USER), SYSDATE, 'Onboarding Completed. UCIC: ' || v_ucic
                );

                p_message := 'Customer approved. UCIC: ' || v_ucic;
            ELSE
                -- Move to next stage
                INSERT INTO bcos_approval_workflow (
                    customer_id, workflow_stage, stage_status, created_date
                ) VALUES (
                    p_customer_id, 'FINAL_APPROVAL', 'PENDING', SYSDATE
                );
                p_message := 'Stage ' || v_stage || ' approved. Moved to next stage.';
            END IF;

        ELSIF p_action = 'REJECT' THEN
            UPDATE bcos_approval_workflow
            SET    stage_status  = 'REJECTED',
                   action_by     = NVL(V('APP_USER'), USER),
                   action_date   = SYSDATE,
                   remarks       = p_remarks
            WHERE  customer_id   = p_customer_id
            AND    workflow_stage = v_stage;

            UPDATE bcos_customers
            SET    status        = 'REJECTED',
                   modified_by   = NVL(V('APP_USER'), USER),
                   modified_date  = SYSDATE
            WHERE  customer_id   = p_customer_id;

            p_message := 'Customer application rejected at stage: ' || v_stage;

        ELSIF p_action = 'HOLD' THEN
            UPDATE bcos_approval_workflow
            SET    stage_status  = 'ON_HOLD',
                   action_by     = NVL(V('APP_USER'), USER),
                   action_date   = SYSDATE,
                   remarks       = p_remarks
            WHERE  customer_id   = p_customer_id
            AND    workflow_stage = v_stage;

            p_message := 'Customer application put on hold.';
        END IF;

        log_audit('BCOS_CUSTOMERS', p_customer_id, p_action,
                  NULL, TO_CLOB(p_remarks), 'Workflow Action: ' || p_action);

        p_status := 'SUCCESS';
        COMMIT;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_status  := 'ERROR';
            p_message := 'No pending workflow stage found for this customer.';
        WHEN OTHERS THEN
            ROLLBACK;
            p_status  := 'ERROR';
            p_message := 'Workflow error: ' || SQLERRM;
    END process_workflow;


    -- AUDIT TRAIL
    PROCEDURE log_audit (
        p_table_name    IN  VARCHAR2,
        p_record_id     IN  NUMBER,
        p_action_type   IN  VARCHAR2,
        p_old_value     IN  CLOB DEFAULT NULL,
        p_new_value     IN  CLOB DEFAULT NULL,
        p_remarks       IN  VARCHAR2 DEFAULT NULL
    ) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO bcos_audit_trail (
            table_name, record_id, action_type,
            old_value, new_value,
            action_by, action_date,
            session_id, remarks
        ) VALUES (
            p_table_name, p_record_id, p_action_type,
            p_old_value, p_new_value,
            NVL(V('APP_USER'), USER), SYSDATE,
            NVL(V('APP_SESSION'), SYS_CONTEXT('USERENV','SESSIONID')),
            p_remarks
        );
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            NULL; -- Audit should never break main transaction
    END log_audit;


    -- DASHBOARD SUMMARY
    FUNCTION get_dashboard_summary RETURN SYS_REFCURSOR AS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT
                COUNT(*)                                            AS total_customers,
                SUM(CASE WHEN status = 'PENDING'      THEN 1 ELSE 0 END) AS pending,
                SUM(CASE WHEN status = 'UNDER_REVIEW' THEN 1 ELSE 0 END) AS under_review,
                SUM(CASE WHEN status = 'APPROVED'     THEN 1 ELSE 0 END) AS approved,
                SUM(CASE WHEN status = 'REJECTED'     THEN 1 ELSE 0 END) AS rejected,
                SUM(CASE WHEN status = 'DUPLICATE'    THEN 1 ELSE 0 END) AS duplicates,
                SUM(CASE WHEN TRUNC(created_date) = TRUNC(SYSDATE) THEN 1 ELSE 0 END) AS today_registrations
            FROM bcos_customers;

        RETURN v_cursor;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_dashboard_summary;

END bcos_pkg;
/
