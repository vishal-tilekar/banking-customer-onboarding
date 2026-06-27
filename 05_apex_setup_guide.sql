-- ============================================================
-- Banking Customer Onboarding System
-- Oracle APEX Application Setup Guide
-- Environment: apex.oracle.com (Free Cloud)
-- ============================================================

/*
====================================================================
APEX APPLICATION STRUCTURE
====================================================================

Application Name : Banking Customer Onboarding System (BCOS)
Application ID   : (Auto assigned by APEX)
Theme            : Universal Theme (42)
Authentication   : APEX Accounts
Authorization    : Role-based (Admin / Reviewer / Viewer)

====================================================================
PAGES TO CREATE IN APEX
====================================================================

PAGE 1  : Login Page (Default)
PAGE 2  : Dashboard (Home)
PAGE 3  : Customer Registration Form
PAGE 4  : Customer List (Interactive Report)
PAGE 5  : Customer Details
PAGE 6  : KYC Verification
PAGE 7  : Document Upload
PAGE 8  : Approval Workflow
PAGE 9  : Audit Trail Report
PAGE 10 : Admin Settings / Lookup Management

====================================================================
PAGE 2: DASHBOARD
====================================================================

Region Type : Static Content + PL/SQL Dynamic Content
Cards showing:
  - Total Customers
  - Pending Applications
  - Approved Today
  - Rejected
  - Duplicate Detected

SQL for Dashboard Cards:
----------------------------
SELECT
  COUNT(*)                                                     AS total,
  SUM(CASE WHEN status = 'PENDING'      THEN 1 ELSE 0 END)   AS pending,
  SUM(CASE WHEN status = 'APPROVED'     THEN 1 ELSE 0 END)   AS approved,
  SUM(CASE WHEN status = 'REJECTED'     THEN 1 ELSE 0 END)   AS rejected,
  SUM(CASE WHEN status = 'DUPLICATE'    THEN 1 ELSE 0 END)   AS duplicates,
  SUM(CASE WHEN TRUNC(created_date) = TRUNC(SYSDATE) THEN 1 ELSE 0 END) AS today
FROM bcos_customers

Chart (Pie / Bar) - Status Distribution:
----------------------------
SELECT status AS label, COUNT(*) AS value
FROM   bcos_customers
GROUP  BY status

====================================================================
PAGE 3: CUSTOMER REGISTRATION FORM
====================================================================

Form Items:
  P3_FIRST_NAME       Text Field        (Required)
  P3_LAST_NAME        Text Field        (Required)
  P3_DATE_OF_BIRTH    Date Picker       (Required)
  P3_GENDER           Select List       (LOV: GENDER lookup)
  P3_MOBILE_NUMBER    Text Field        (Required, 10 digits)
  P3_EMAIL_ADDRESS    Text Field        (Email validation)
  P3_PAN_NUMBER       Text Field        (UPPERCASE, 10 chars)
  P3_AADHAR_NUMBER    Text Field        (12 digits, masked)
  P3_CUSTOMER_TYPE    Select List       (LOV: CUSTOMER_TYPE lookup)

Validations:
  - PAN format: ^[A-Z]{5}[0-9]{4}[A-Z]{1}$
  - Aadhar: 12 digits only
  - Mobile: 10 digits only
  - Age: >= 18 years

Process (PL/SQL):
----------------------------
DECLARE
  v_id    NUMBER;
  v_sts   VARCHAR2(50);
  v_msg   VARCHAR2(500);
BEGIN
  bcos_pkg.register_customer(
    p_first_name    => :P3_FIRST_NAME,
    p_last_name     => :P3_LAST_NAME,
    p_dob           => TO_DATE(:P3_DATE_OF_BIRTH, 'DD-MON-YYYY'),
    p_gender        => :P3_GENDER,
    p_mobile        => :P3_MOBILE_NUMBER,
    p_email         => :P3_EMAIL_ADDRESS,
    p_pan           => UPPER(:P3_PAN_NUMBER),
    p_aadhar        => :P3_AADHAR_NUMBER,
    p_customer_type => :P3_CUSTOMER_TYPE,
    p_customer_id   => v_id,
    p_status        => v_sts,
    p_message       => v_msg
  );

  IF v_sts = 'SUCCESS' THEN
    :P3_CUSTOMER_ID := v_id;
    APEX_APPLICATION.G_PRINT_SUCCESS_MESSAGE := v_msg;
  ELSE
    RAISE_APPLICATION_ERROR(-20001, v_msg);
  END IF;
END;

====================================================================
PAGE 4: CUSTOMER LIST — INTERACTIVE REPORT
====================================================================

SQL Query:
----------------------------
SELECT
  c.customer_id,
  c.ucic_number,
  c.first_name || ' ' || c.last_name       AS full_name,
  c.mobile_number,
  c.email_address,
  c.pan_number,
  c.customer_type,
  CASE c.status
    WHEN 'APPROVED'     THEN '<span class="t-Badge t-Badge--success">'  || c.status || '</span>'
    WHEN 'REJECTED'     THEN '<span class="t-Badge t-Badge--danger">'   || c.status || '</span>'
    WHEN 'PENDING'      THEN '<span class="t-Badge t-Badge--warning">'  || c.status || '</span>'
    WHEN 'UNDER_REVIEW' THEN '<span class="t-Badge t-Badge--info">'     || c.status || '</span>'
    WHEN 'DUPLICATE'    THEN '<span class="t-Badge t-Badge--neutral">'  || c.status || '</span>'
    ELSE c.status
  END                                        AS status_badge,
  TO_CHAR(c.created_date, 'DD-Mon-YYYY')    AS registered_on
FROM bcos_customers c
ORDER BY c.created_date DESC

Enable: Column Link on customer_id → Page 5 (Customer Details)
Enable: Download (CSV, Excel, PDF)
Enable: Search Bar

====================================================================
PAGE 5: CUSTOMER DETAILS
====================================================================

Regions:
  1. Customer Information (Form - Read Only)
  2. KYC Details (Interactive Report)
  3. Documents (Interactive Report + Upload button)
  4. Workflow Timeline (Classic Report)
  5. Audit Trail (Classic Report)

Workflow Action Buttons:
  [Approve] [Reject] [On Hold]

Dynamic Action on [Approve]:
  Execute PL/SQL:
    DECLARE
      v_sts VARCHAR2(50);
      v_msg VARCHAR2(500);
    BEGIN
      bcos_pkg.process_workflow(
        p_customer_id => :P5_CUSTOMER_ID,
        p_action      => 'APPROVE',
        p_remarks     => :P5_REMARKS,
        p_status      => v_sts,
        p_message     => v_msg
      );
      :P5_MSG := v_msg;
    END;

====================================================================
PAGE 6: KYC VERIFICATION
====================================================================

Items:
  P6_CUSTOMER_ID    Hidden
  P6_KYC_TYPE       Select List  (LOV: KYC_TYPE)
  P6_KYC_NUMBER     Text Field
  P6_EXPIRY_DATE    Date Picker
  P6_REMARKS        Textarea

Process:
  DECLARE
    v_sts VARCHAR2(50);
    v_msg VARCHAR2(500);
  BEGIN
    bcos_pkg.verify_kyc(
      p_customer_id => :P6_CUSTOMER_ID,
      p_kyc_type    => :P6_KYC_TYPE,
      p_kyc_number  => :P6_KYC_NUMBER,
      p_status      => v_sts,
      p_message     => v_msg
    );
  END;

====================================================================
PAGE 7: DOCUMENT UPLOAD
====================================================================

Items:
  P7_CUSTOMER_ID    Hidden
  P7_DOC_TYPE       Select List   (LOV: DOC_TYPE)
  P7_DOCUMENT       File Browse   (BLOB column)
  P7_REMARKS        Textarea

Process (APEX File Upload to BLOB):
  INSERT INTO bcos_documents (
    customer_id, document_type, document_name,
    document_blob, document_mime, file_size,
    uploaded_by, uploaded_date
  )
  SELECT
    :P7_CUSTOMER_ID,
    :P7_DOC_TYPE,
    filename,
    blob_content,
    mime_type,
    dbms_lob.getlength(blob_content),
    :APP_USER,
    SYSDATE
  FROM apex_application_temp_files
  WHERE name = :P7_DOCUMENT;

====================================================================
PAGE 9: AUDIT TRAIL — INTERACTIVE REPORT
====================================================================

SQL:
  SELECT
    audit_id,
    table_name,
    record_id,
    action_type,
    action_by,
    TO_CHAR(action_date, 'DD-Mon-YYYY HH24:MI:SS') AS action_date,
    remarks,
    DBMS_LOB.SUBSTR(new_value, 200, 1)  AS new_value_preview
  FROM bcos_audit_trail
  ORDER BY action_date DESC

====================================================================
AUTHORIZATION SCHEMES
====================================================================

1. IS_ADMIN
   PL/SQL: RETURN APEX_ACL.HAS_USER_ROLE(
             p_application_id => :APP_ID,
             p_user_name      => :APP_USER,
             p_role_static_id => 'ADMIN');

2. IS_REVIEWER
   PL/SQL: RETURN APEX_ACL.HAS_USER_ROLE(
             p_application_id => :APP_ID,
             p_user_name      => :APP_USER,
             p_role_static_id => 'REVIEWER');

3. IS_VIEWER (Read-only)
   Applied to all report pages

====================================================================
ROLES TO CREATE IN APEX ACCESS CONTROL
====================================================================
  Role: ADMIN     → Full access
  Role: REVIEWER  → Can approve/reject
  Role: VIEWER    → Read-only access

====================================================================
NAVIGATION MENU
====================================================================
  🏠 Dashboard
  👤 Customer Registration
  📋 Customer List
  ✅ KYC Verification
  📁 Document Management
  🔄 Approval Workflow
  📊 Reports
  🔍 Audit Trail
  ⚙️  Settings (Admin only)

====================================================================
*/
