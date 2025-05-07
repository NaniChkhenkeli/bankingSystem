CREATE OR REPLACE PACKAGE BODY bank_account_pkg AS
    -- Generate a random account number
    FUNCTION generate_account_number RETURN VARCHAR2 IS
        v_prefix VARCHAR2(4) := 'BNK';
        v_random_num NUMBER;
    BEGIN
        v_random_num := FLOOR(DBMS_RANDOM.VALUE(10000000, 99999999));
        RETURN v_prefix || v_random_num;
    END generate_account_number;
    
    -- Create a new account
    PROCEDURE create_account(
        p_customer_id IN NUMBER,
        p_account_type IN VARCHAR2,
        p_initial_deposit IN NUMBER DEFAULT 0,
        p_interest_rate IN NUMBER DEFAULT NULL,
        p_account_number OUT VARCHAR2,
        p_account_id OUT NUMBER
    ) IS
        v_account_number VARCHAR2(20);
        v_account_id NUMBER;
    BEGIN
        -- Validate initial deposit
        IF p_initial_deposit < 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Initial deposit cannot be negative');
        END IF;
        
        -- Generate unique account number
        LOOP
            v_account_number := generate_account_number();
            BEGIN
                INSERT INTO accounts (
                    customer_id,
                    account_type,
                    account_number,
                    balance,
                    interest_rate
                ) VALUES (
                    p_customer_id,
                    p_account_type,
                    v_account_number,
                    p_initial_deposit,
                    p_interest_rate
                )
                RETURNING account_id INTO v_account_id;
                
                EXIT; -- Exit loop if insert succeeds
            EXCEPTION
                WHEN DUP_VAL_ON_INDEX THEN
                    NULL; -- Try again with new number
            END;
        END LOOP;
        
        -- Record initial deposit if any
        IF p_initial_deposit > 0 THEN
            INSERT INTO transactions (
                account_id,
                transaction_type,
                amount,
                description
            ) VALUES (
                v_account_id,
                'DEPOSIT',
                p_initial_deposit,
                'Initial deposit'
            );
        END IF;
        
        p_account_number := v_account_number;
        p_account_id := v_account_id;
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END create_account;
    
    -- Close an account
    PROCEDURE close_account(p_account_id IN NUMBER) IS
        v_balance NUMBER;
    BEGIN
        -- Check account balance
        SELECT balance INTO v_balance
        FROM accounts
        WHERE account_id = p_account_id
        FOR UPDATE;
        
        IF v_balance != 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Cannot close account with non-zero balance');
        END IF;
        
        UPDATE accounts
        SET status = 'CLOSED'
        WHERE account_id = p_account_id;
        
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'Account not found');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END close_account;
    
    -- Deposit money into an account
    PROCEDURE deposit(
        p_account_id IN NUMBER,
        p_amount IN NUMBER,
        p_description IN VARCHAR2 DEFAULT NULL
    ) IS
        v_balance NUMBER;
    BEGIN
        IF p_amount <= 0 THEN
            RAISE_APPLICATION_ERROR(-20004, 'Deposit amount must be positive');
        END IF;
        
        -- Update account balance
        UPDATE accounts
        SET balance = balance + p_amount
        WHERE account_id = p_account_id
        RETURNING balance INTO v_balance;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Account not found');
        END IF;
        
        -- Record transaction
        INSERT INTO transactions (
            account_id,
            transaction_type,
            amount,
            description
        ) VALUES (
            p_account_id,
            'DEPOSIT',
            p_amount,
            p_description
        );
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END deposit;
    
    -- Withdraw money from an account
    PROCEDURE withdraw(
        p_account_id IN NUMBER,
        p_amount IN NUMBER,
        p_description IN VARCHAR2 DEFAULT NULL
    ) IS
        v_balance NUMBER;
        v_status VARCHAR2(10);
    BEGIN
        IF p_amount <= 0 THEN
            RAISE_APPLICATION_ERROR(-20005, 'Withdrawal amount must be positive');
        END IF;
        
        -- Check account status and get balance
        SELECT balance, status INTO v_balance, v_status
        FROM accounts
        WHERE account_id = p_account_id
        FOR UPDATE;
        
        IF v_status != 'ACTIVE' THEN
            RAISE_APPLICATION_ERROR(-20006, 'Account is not active for withdrawals');
        END IF;
        
        IF v_balance < p_amount THEN
            RAISE_APPLICATION_ERROR(-20007, 'Insufficient funds');
        END IF;
        
        -- Update account balance
        UPDATE accounts
        SET balance = balance - p_amount
        WHERE account_id = p_account_id;
        
        -- Record transaction
        INSERT INTO transactions (
            account_id,
            transaction_type,
            amount,
            description
        ) VALUES (
            p_account_id,
            'WITHDRAWAL',
            p_amount,
            p_description
        );
        
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'Account not found');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END withdraw;
    
    -- Transfer money between accounts
    PROCEDURE transfer(
        p_from_account_id IN NUMBER,
        p_to_account_id IN NUMBER,
        p_amount IN NUMBER,
        p_description IN VARCHAR2 DEFAULT NULL
    ) IS
        v_from_balance NUMBER;
        v_from_status VARCHAR2(10);
        v_to_status VARCHAR2(10);
        v_transaction_id NUMBER;
    BEGIN
        IF p_amount <= 0 THEN
            RAISE_APPLICATION_ERROR(-20008, 'Transfer amount must be positive');
        END IF;
        
        IF p_from_account_id = p_to_account_id THEN
            RAISE_APPLICATION_ERROR(-20009, 'Cannot transfer to the same account');
        END IF;
        
        -- Check from account status and get balance
        SELECT balance, status INTO v_from_balance, v_from_status
        FROM accounts
        WHERE account_id = p_from_account_id
        FOR UPDATE;
        
        IF v_from_status != 'ACTIVE' THEN
            RAISE_APPLICATION_ERROR(-20010, 'Source account is not active for transfers');
        END IF;
        
        -- Check to account status
        SELECT status INTO v_to_status
        FROM accounts
        WHERE account_id = p_to_account_id
        FOR UPDATE;
        
        IF v_to_status != 'ACTIVE' THEN
            RAISE_APPLICATION_ERROR(-20011, 'Destination account is not active for transfers');
        END IF;
        
        IF v_from_balance < p_amount THEN
            RAISE_APPLICATION_ERROR(-20007, 'Insufficient funds for transfer');
        END IF;
        
        -- Update balances
        UPDATE accounts
        SET balance = balance - p_amount
        WHERE account_id = p_from_account_id;
        
        UPDATE accounts
        SET balance = balance + p_amount
        WHERE account_id = p_to_account_id;
        
        -- Record withdrawal transaction
        INSERT INTO transactions (
            account_id,
            transaction_type,
            amount,
            description,
            related_account_id,
            status
        ) VALUES (
            p_from_account_id,
            'TRANSFER',
            p_amount,
            p_description,
            p_to_account_id,
            'COMPLETED'
        )
        RETURNING transaction_id INTO v_transaction_id;
        
        -- Record deposit transaction
        INSERT INTO transactions (
            account_id,
            transaction_type,
            amount,
            description,
            related_account_id,
            status
        ) VALUES (
            p_to_account_id,
            'TRANSFER',
            p_amount,
            p_description,
            p_from_account_id,
            'COMPLETED'
        );
        
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20003, 'One or both accounts not found');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END transfer;
    
    -- Create a new loan account
    PROCEDURE create_loan(
        p_customer_id IN NUMBER,
        p_principal_amount IN NUMBER,
        p_interest_rate IN NUMBER,
        p_term_months IN NUMBER,
        p_loan_account_id OUT NUMBER
    ) IS
        v_account_number VARCHAR2(20);
        v_account_id NUMBER;
        v_monthly_payment NUMBER;
        v_end_date DATE;
    BEGIN
        IF p_principal_amount <= 0 OR p_interest_rate <= 0 OR p_term_months <= 0 THEN
            RAISE_APPLICATION_ERROR(-20012, 'Principal, interest rate, and term must be positive');
        END IF;
        
        -- Calculate monthly payment (simple interest for example)
        v_monthly_payment := (p_principal_amount * (1 + (p_interest_rate/100) * (p_term_months/12))) / p_term_months;
        v_end_date := ADD_MONTHS(SYSDATE, p_term_months);
        
        -- Create loan account with negative balance
        create_account(
            p_customer_id => p_customer_id,
            p_account_type => 'LOAN',
            p_initial_deposit => -p_principal_amount,
            p_interest_rate => p_interest_rate,
            p_account_number => v_account_number,
            p_account_id => v_account_id
        );
        
        -- Create loan record
        INSERT INTO loans (
            account_id,
            principal_amount,
            interest_rate,
            term_months,
            start_date,
            end_date,
            monthly_payment,
            remaining_balance
        ) VALUES (
            v_account_id,
            p_principal_amount,
            p_interest_rate,
            p_term_months,
            SYSDATE,
            v_end_date,
            v_monthly_payment,
            p_principal_amount
        );
        
        p_loan_account_id := v_account_id;
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END create_loan;
    
    -- Process loan payment
    PROCEDURE process_loan_payment(
        p_loan_id IN NUMBER,
        p_amount IN NUMBER
    ) IS
        v_account_id NUMBER;
        v_remaining_balance NUMBER;
        v_monthly_payment NUMBER;
        v_interest_rate NUMBER;
        v_interest_amount NUMBER;
        v_principal_amount NUMBER;
    BEGIN
        IF p_amount <= 0 THEN
            RAISE_APPLICATION_ERROR(-20013, 'Payment amount must be positive');
        END IF;
        
        -- Get loan details
        SELECT l.account_id, l.remaining_balance, l.monthly_payment, l.interest_rate
        INTO v_account_id, v_remaining_balance, v_monthly_payment, v_interest_rate
        FROM loans l
        WHERE l.loan_id = p_loan_id
        FOR UPDATE;
        
        -- Calculate interest and principal portions
        v_interest_amount := (v_remaining_balance * (v_interest_rate/100)) / 12;
        IF v_interest_amount > p_amount THEN
            v_interest_amount := p_amount;
            v_principal_amount := 0;
        ELSE
            v_principal_amount := p_amount - v_interest_amount;
        END IF;
        
        -- Update loan balance
        UPDATE loans
        SET remaining_balance = remaining_balance - v_principal_amount
        WHERE loan_id = p_loan_id;
        
        -- Update account balance (loan accounts have negative balance)
        UPDATE accounts
        SET balance = balance + p_amount
        WHERE account_id = v_account_id;
        
        -- Record payment transaction
        INSERT INTO transactions (
            account_id,
            transaction_type,
            amount,
            description
        ) VALUES (
            v_account_id,
            'DEPOSIT',
            p_amount,
            'Loan payment - Interest: ' || v_interest_amount || ', Principal: ' || v_principal_amount
        );
        
        -- Check if loan is fully paid
        SELECT remaining_balance INTO v_remaining_balance
        FROM loans
        WHERE loan_id = p_loan_id;
        
        IF v_remaining_balance <= 0 THEN
            UPDATE loans
            SET status = 'PAID',
                remaining_balance = 0
            WHERE loan_id = p_loan_id;
            
            UPDATE accounts
            SET status = 'INACTIVE'
            WHERE account_id = v_account_id;
        END IF;
        
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20014, 'Loan not found');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END process_loan_payment;
    
    -- Get account balance
    FUNCTION get_account_balance(p_account_id IN NUMBER) RETURN NUMBER IS
        v_balance NUMBER;
    BEGIN
        SELECT balance INTO v_balance
        FROM accounts
        WHERE account_id = p_account_id;
        
        RETURN v_balance;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'Account not found');
    END get_account_balance;
    
    -- Get all accounts for a customer
    FUNCTION get_customer_accounts(p_customer_id IN NUMBER) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
        SELECT account_id, account_number, account_type, balance, status, open_date
        FROM accounts
        WHERE customer_id = p_customer_id
        ORDER BY open_date DESC;
        
        RETURN v_cursor;
    END get_customer_accounts;
    
    -- Get transactions for an account
    FUNCTION get_account_transactions(p_account_id IN NUMBER, p_days IN NUMBER DEFAULT 30) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
        SELECT transaction_id, transaction_type, amount, transaction_date, description, related_account_id, status
        FROM transactions
        WHERE account_id = p_account_id
        AND transaction_date >= SYSDATE - p_days
        ORDER BY transaction_date DESC;
        
        RETURN v_cursor;
    END get_account_transactions;
    
    -- Calculate daily interest for savings accounts
    PROCEDURE calculate_daily_interest IS
        CURSOR c_savings_accounts IS
            SELECT account_id, balance, interest_rate
            FROM accounts
            WHERE account_type = 'SAVINGS'
            AND status = 'ACTIVE'
            AND interest_rate > 0
            FOR UPDATE;
            
        v_interest_amount NUMBER;
        v_daily_rate NUMBER;
    BEGIN
        FOR acc IN c_savings_accounts LOOP
            -- Calculate daily interest (annual rate / 365)
            v_daily_rate := acc.interest_rate / 36500; -- Divided by 100 for percentage
            v_interest_amount := acc.balance * v_daily_rate;
            
            -- Apply interest if more than 0.01
            IF v_interest_amount >= 0.01 THEN
                -- Update balance
                UPDATE accounts
                SET balance = balance + v_interest_amount
                WHERE account_id = acc.account_id;
                
                -- Record interest transaction
                INSERT INTO transactions (
                    account_id,
                    transaction_type,
                    amount,
                    description
                ) VALUES (
                    acc.account_id,
                    'INTEREST',
                    v_interest_amount,
                    'Daily interest'
                );
            END IF;
        END LOOP;
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END calculate_daily_interest;
END bank_account_pkg;
/

CREATE OR REPLACE PACKAGE BODY bank_utility_pkg AS
    -- Create a new customer
    PROCEDURE create_customer(
        p_first_name IN VARCHAR2,
        p_last_name IN VARCHAR2,
        p_email IN VARCHAR2,
        p_phone IN VARCHAR2 DEFAULT NULL,
        p_address IN VARCHAR2 DEFAULT NULL,
        p_dob IN DATE DEFAULT NULL,
        p_customer_id OUT NUMBER
    ) IS
    BEGIN
        -- Validate required fields
        IF p_first_name IS NULL OR p_last_name IS NULL OR p_email IS NULL THEN
            RAISE_APPLICATION_ERROR(-20015, 'First name, last name, and email are required');
        END IF;
        
        -- Validate email format (simple check)
        IF INSTR(p_email, '@') = 0 THEN
            RAISE_APPLICATION_ERROR(-20016, 'Invalid email format');
        END IF;
        
        INSERT INTO customers (
            first_name,
            last_name,
            email,
            phone,
            address,
            date_of_birth
        ) VALUES (
            p_first_name,
            p_last_name,
            p_email,
            p_phone,
            p_address,
            p_dob
        )
        RETURNING customer_id INTO p_customer_id;
        
        COMMIT;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20017, 'Email already exists');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END create_customer;
    
    -- Update customer information
    PROCEDURE update_customer(
        p_customer_id IN NUMBER,
        p_first_name IN VARCHAR2 DEFAULT NULL,
        p_last_name IN VARCHAR2 DEFAULT NULL,
        p_email IN VARCHAR2 DEFAULT NULL,
        p_phone IN VARCHAR2 DEFAULT NULL,
        p_address IN VARCHAR2 DEFAULT NULL
    ) IS
        v_update_count NUMBER;
    BEGIN
        -- At least one field must be provided
        IF p_first_name IS NULL AND p_last_name IS NULL AND p_email IS NULL 
           AND p_phone IS NULL AND p_address IS NULL THEN
            RAISE_APPLICATION_ERROR(-20018, 'At least one field must be provided for update');
        END IF;
        
        -- Validate email format if provided
        IF p_email IS NOT NULL AND INSTR(p_email, '@') = 0 THEN
            RAISE_APPLICATION_ERROR(-20016, 'Invalid email format');
        END IF;
        
        UPDATE customers
        SET 
            first_name = NVL(p_first_name, first_name),
            last_name = NVL(p_last_name, last_name),
            email = NVL(p_email, email),
            phone = NVL(p_phone, phone),
            address = NVL(p_address, address)
        WHERE customer_id = p_customer_id;
        
        v_update_count := SQL%ROWCOUNT;
        
        IF v_update_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20019, 'Customer not found');
        END IF;
        
        COMMIT;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20017, 'Email already exists');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END update_customer;
    
    -- Get customer details
    FUNCTION get_customer_details(p_customer_id IN NUMBER) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
        SELECT customer_id, first_name, last_name, email, phone, address, date_of_birth, created_at
        FROM customers
        WHERE customer_id = p_customer_id;
        
        RETURN v_cursor;
    END get_customer_details;
    
    -- Get daily transactions
    FUNCTION get_daily_transactions(p_date IN DATE DEFAULT TRUNC(SYSDATE)) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
        SELECT t.transaction_id, a.account_number, t.transaction_type, t.amount, 
               t.transaction_date, t.description, t.status,
               c.first_name || ' ' || c.last_name AS customer_name
        FROM transactions t
        JOIN accounts a ON t.account_id = a.account_id
        JOIN customers c ON a.customer_id = c.customer_id
        WHERE TRUNC(t.transaction_date) = TRUNC(p_date)
        ORDER BY t.transaction_date DESC;
        
        RETURN v_cursor;
    END get_daily_transactions;
    
    -- Freeze an account
    PROCEDURE freeze_account(p_account_id IN NUMBER) IS
        v_update_count NUMBER;
    BEGIN
        UPDATE accounts
        SET status = 'FROZEN'
        WHERE account_id = p_account_id
        AND status = 'ACTIVE';
        
        v_update_count := SQL%ROWCOUNT;
        
        IF v_update_count = 0 THEN
            -- Check if account exists
            BEGIN
                SELECT 1 INTO v_update_count
                FROM accounts
                WHERE account_id = p_account_id;
                
                RAISE_APPLICATION_ERROR(-20020, 'Account is not active or already frozen');
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(-20003, 'Account not found');
            END;
        END IF;
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END freeze_account;
    
    -- Unfreeze an account
    PROCEDURE unfreeze_account(p_account_id IN NUMBER) IS
        v_update_count NUMBER;
    BEGIN
        UPDATE accounts
        SET status = 'ACTIVE'
        WHERE account_id = p_account_id
        AND status = 'FROZEN';
        
        v_update_count := SQL%ROWCOUNT;
        
        IF v_update_count = 0 THEN
            -- Check if account exists
            BEGIN
                SELECT 1 INTO v_update_count
                FROM accounts
                WHERE account_id = p_account_id;
                
                RAISE_APPLICATION_ERROR(-20021, 'Account is not frozen');
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(-20003, 'Account not found');
            END;
        END IF;
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END unfreeze_account;
    
    -- Validate account belongs to customer
    FUNCTION validate_account(p_account_id IN NUMBER, p_customer_id IN NUMBER DEFAULT NULL) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        IF p_customer_id IS NULL THEN
            -- Just check if account exists
            SELECT COUNT(*) INTO v_count
            FROM accounts
            WHERE account_id = p_account_id;
        ELSE
            -- Check if account belongs to customer
            SELECT COUNT(*) INTO v_count
            FROM accounts
            WHERE account_id = p_account_id
            AND customer_id = p_customer_id;
        END IF;
        
        RETURN v_count > 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END validate_account;
END bank_utility_pkg;
