-- ============================================================
-- Banking Customer Onboarding System
-- Triggers
-- Compatible: Oracle 19c
-- ============================================================

-- 
-- TRIGGER 1: Customer Audit Trail (UPDATE)
-- Logs every update on bcos_customers automatically

CREATE OR REPLACE TRIGGER trg_bcos_customers_audit
AFTER UPDATE ON bcos_customers
FOR EACH ROW
DECLARE
    v_old_value     CLOB;
    v_new_value     CLOB;
BEGIN
    v_old_value := 'Status: ' || :OLD.status ||
                   ' | Mobile: ' || :OLD.mobile_number ||
                   ' | Email: ' || :OLD.email_address;

    v_new_value := 'Status: ' || :NEW.status ||
                   ' | Mobile: ' || :NEW.mobile_number ||
                   ' | Email: ' || :NEW.email_address;

    bcos_pkg.log_audit(
        p_table_name  => 'BCOS_CUSTOMERS',
        p_record_id   => :NEW.customer_id,
        p_action_type => 'UPDATE',
        p_old_value   => v_old_value,
        p_new_value   => v_new_value,
        p_remarks     => 'Auto Audit: Customer Record Updated'
    );
END;
/


-- TRIGGER 2: Document Upload Audit
-- Logs every document upload
CREATE OR REPLACE TRIGGER trg_bcos_documents_audit
AFTER INSERT OR UPDATE ON bcos_documents
FOR EACH ROW
DECLARE
    v_action    VARCHAR2(10);
BEGIN
    v_action := CASE WHEN INSERTING THEN 'INSERT' ELSE 'UPDATE' END;

    bcos_pkg.log_audit(
        p_table_name  => 'BCOS_DOCUMENTS',
        p_record_id   => :NEW.document_id,
        p_action_type => v_action,
        p_new_value   => TO_CLOB('Doc Type: ' || :NEW.document_type ||
                                 ' | Status: ' || :NEW.upload_status ||
                                 ' | Customer ID: ' || :NEW.customer_id),
        p_remarks     => 'Document ' || v_action
    );
END;
/


-- TRIGGER 3: 
-- Automatically marks customer as DUPLICATE if found

CREATE OR REPLACE TRIGGER trg_bcos_duplicate_check
BEFORE INSERT ON bcos_customers
FOR EACH ROW
DECLARE
    v_dup_result    VARCHAR2(5);
BEGIN
    v_dup_result := bcos_pkg.check_duplicate(
        p_pan         => :NEW.pan_number,
        p_aadhar      => :NEW.aadhar_number,
        p_mobile      => :NEW.mobile_number,
        p_email       => :NEW.email_address
    );

    IF v_dup_result = 'Y' THEN
        :NEW.status := 'DUPLICATE';
    END IF;
END;
/


-- TRIGGER 4: KYC Status Change — auto update customer status
-- When all KYC verified, move customer to UNDER_REVIEW
CREATE OR REPLACE TRIGGER trg_bcos_kyc_status
AFTER UPDATE OF kyc_status ON bcos_kyc_details
FOR EACH ROW
DECLARE
    v_pending_count     NUMBER;
    v_failed_count      NUMBER;
BEGIN
    IF :NEW.kyc_status = 'VERIFIED' THEN
        -- Check if any KYC still pending for this customer
        SELECT COUNT(1) INTO v_pending_count
        FROM   bcos_kyc_details
        WHERE  customer_id = :NEW.customer_id
        AND    kyc_status  IN ('PENDING');

        SELECT COUNT(1) INTO v_failed_count
        FROM   bcos_kyc_details
        WHERE  customer_id = :NEW.customer_id
        AND    kyc_status  = 'FAILED';

        IF v_failed_count > 0 THEN
            -- KYC Failed — mark customer for review
            UPDATE bcos_customers
            SET    status       = 'UNDER_REVIEW',
                   modified_date = SYSDATE
            WHERE  customer_id  = :NEW.customer_id;

        ELSIF v_pending_count = 0 THEN
            -- All KYC verified — move to UNDER_REVIEW for doc check
            UPDATE bcos_customers
            SET    status       = 'UNDER_REVIEW',
                   modified_date = SYSDATE
            WHERE  customer_id  = :NEW.customer_id
            AND    status       = 'PENDING';
        END IF;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- Do not break main transaction
END;
/


-- TRIGGER 5: Workflow Stage Change Audit
CREATE OR REPLACE TRIGGER trg_bcos_workflow_audit
AFTER INSERT OR UPDATE ON bcos_approval_workflow
FOR EACH ROW
DECLARE
    v_action    VARCHAR2(10);
BEGIN
    v_action := CASE WHEN INSERTING THEN 'INSERT' ELSE 'UPDATE' END;

    bcos_pkg.log_audit(
        p_table_name  => 'BCOS_APPROVAL_WORKFLOW',
        p_record_id   => :NEW.workflow_id,
        p_action_type => v_action,
        p_new_value   => TO_CLOB('Stage: ' || :NEW.workflow_stage ||
                                 ' | Status: ' || :NEW.stage_status ||
                                 ' | Customer: ' || :NEW.customer_id),
        p_remarks     => 'Workflow Stage: ' || :NEW.workflow_stage
    );
END;
/

COMMIT;
