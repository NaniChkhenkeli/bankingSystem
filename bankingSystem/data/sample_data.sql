-- Insert sample customers
DECLARE
    v_customer1_id NUMBER;
    v_customer2_id NUMBER;
    v_account1_id NUMBER;
    v_account2_id NUMBER;
    v_account3_id NUMBER;
    v_loan_id NUMBER;
    v_account_num VARCHAR2(20);
BEGIN
    -- Create customers
    bank_utility_pkg.create_customer(
        p_first_name => 'John',
        p_last_name => 'Smith',
        p_email => 'john.smith@example.com',
        p_phone => '555-0101',
        p_customer_id => v_customer1_id
    );
    
    bank_utility_pkg.create_customer(
        p_first_name => 'Sarah',
        p_last_name => 'Johnson',
        p_email => 'sarah.j@example.com',
        p_phone => '555-0202',
        p_customer_id => v_customer2_id
    );
    
    -- Create accounts
    bank_account_pkg.create_account(
        p_customer_id => v_customer1_id,
        p_account_type => 'CHECKING',
        p_initial_deposit => 1000,
        p_account_number => v_account_num,
        p_account_id => v_account1_id
    );
    
    bank_account_pkg.create_account(
        p_customer_id => v_customer1_id,
        p_account_type => 'SAVINGS',
        p_initial_deposit => 5000,
        p_interest_rate => 1.5,
        p_account_number => v_account_num,
        p_account_id => v_account2_id
    );
    
    bank_account_pkg.create_account(
        p_customer_id => v_customer2_id,
        p_account_type => 'CHECKING',
        p_initial_deposit => 2000,
        p_account_number => v_account_num,
        p_account_id => v_account3_id
    );
    
    -- Create a loan
    bank_account_pkg.create_loan(
        p_customer_id => v_customer1_id,
        p_principal_amount => 10000,
        p_interest_rate => 5,
        p_term_months => 24,
        p_loan_account_id => v_loan_id
    );
    
    COMMIT;
END;
/

-- Perform transactions
BEGIN
    -- Deposit to account 1
    bank_account_pkg.deposit(
        p_account_id => 1,
        p_amount => 500,
        p_description => 'Paycheck deposit'
    );
    
    -- Withdraw from account 1
    bank_account_pkg.withdraw(
        p_account_id => 1,
        p_amount => 200,
        p_description => 'ATM withdrawal'
    );
    
    -- Transfer between accounts
    bank_account_pkg.transfer(
        p_from_account_id => 1,
        p_to_account_id => 2,
        p_amount => 300,
        p_description => 'Monthly savings'
    );
    
    -- Make a loan payment
    bank_account_pkg.process_loan_payment(
        p_loan_id => 1,
        p_amount => 450
    );
    
    COMMIT;
END;
/

-- Calculate daily interest
BEGIN
    bank_account_pkg.calculate_daily_interest;
    COMMIT;
END;
/