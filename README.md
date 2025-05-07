banking system prototype built with Oracle PL/SQL that implements core banking operations including account management, transaction processing, loan handling, and interest calculations. This system demonstrates professional database programming practices with proper transaction control and error handling.

- account MGMT
  create/close checking, savings, loan, credit accounts.
  interest rate configuration for savings account
- transaction processing
  deposits and withdraws with validation
  Transaction history with status tracking
- loan MGMT
  Loan account creation with terms
  Automatic loan status updates
- reporting
  Customer account listings
  Transaction history views
  Daily transaction summaries

Installation:
Oracle Database 11g or later
SQL*Plus or SQL Developer
Execute privileges on target schema

usage example:
xreate customer:
DECLARE
  v_customer_id NUMBER;
BEGIN
  bank_utility_pkg.create_customer(
    p_first_name => 'John',
    p_last_name => 'Doe',
    p_email => 'john.doe@example.com',
    p_phone => '555-123-4567',
    p_customer_id => v_customer_id
  );
  DBMS_OUTPUT.PUT_LINE('Created customer ID: ' || v_customer_id);
END;
/

open savings:
DECLARE
  v_account_num VARCHAR2(20);
  v_account_id NUMBER;
BEGIN
  bank_account_pkg.create_account(
    p_customer_id => 1,
    p_account_type => 'SAVINGS',
    p_initial_deposit => 1000,
    p_interest_rate => 1.5,
    p_account_number => v_account_num,
    p_account_id => v_account_id
  );
  DBMS_OUTPUT.PUT_LINE('Account #' || v_account_num || ' opened with ID: ' || v_account_id);
END;
/

process transactions:
-- Deposit
BEGIN
  bank_account_pkg.deposit(1, 500, 'Paycheck deposit');
END;
/

-- Transfer between accounts
BEGIN
  bank_account_pkg.transfer(1, 2, 300, 'Monthly savings transfer');
END;
/

Contributing:
Fork the repository
Create your feature branch (git checkout -b feature/your-feature)
Commit your changes (git commit -am 'Add some feature')
Push to the branch (git push origin feature/your-feature)
Open a Pull Request


