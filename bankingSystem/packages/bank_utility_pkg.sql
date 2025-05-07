/*
File: bank_utility_pkg.sql
Description: Customer management and utility functions
*/

CREATE OR REPLACE PACKAGE bank_utility_pkg AS
    -- Customer operations
    PROCEDURE create_customer(
        p_first_name IN VARCHAR2,
        p_last_name IN VARCHAR2,
        p_email IN VARCHAR2,
        p_phone IN VARCHAR2 DEFAULT NULL,
        p_address IN VARCHAR2 DEFAULT NULL,
        p_dob IN DATE DEFAULT NULL,
        p_customer_id OUT NUMBER
    );
    
    PROCEDURE update_customer(
        p_customer_id IN NUMBER,
        p_first_name IN VARCHAR2 DEFAULT NULL,
        p_last_name IN VARCHAR2 DEFAULT NULL,
        p_email IN VARCHAR2 DEFAULT NULL,
        p_phone IN VARCHAR2 DEFAULT NULL,
        p_address IN VARCHAR2 DEFAULT NULL
    );
    
    -- Reporting
    FUNCTION get_customer_details(p_customer_id IN NUMBER) RETURN SYS_REFCURSOR;
    FUNCTION get_daily_transactions(p_date IN DATE DEFAULT TRUNC(SYSDATE)) RETURN SYS_REFCURSOR;
    
    -- Security
    PROCEDURE freeze_account(p_account_id IN NUMBER);
    PROCEDURE unfreeze_account(p_account_id IN NUMBER);
    
    -- Data validation
    FUNCTION validate_account(p_account_id IN NUMBER, p_customer_id IN NUMBER DEFAULT NULL) RETURN BOOLEAN;
END bank_utility_pkg;
/

CREATE OR REPLACE PACKAGE BODY bank_utility_pkg AS
    -- Implementation of all procedures/functions from specification
    -- (Include all the package body code from the original implementation)
    -- [Previous package body code goes here exactly as written]
END bank