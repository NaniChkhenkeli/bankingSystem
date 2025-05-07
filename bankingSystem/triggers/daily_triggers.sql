-- Audit trigger for account status changes
CREATE OR REPLACE TRIGGER trg_account_status_change
AFTER UPDATE OF status ON accounts
FOR EACH ROW
WHEN (OLD.status != NEW.status)
BEGIN
    INSERT INTO transactions (
        account_id,
        transaction_type,
        amount,
        description
    ) VALUES (
        :NEW.account_id,
        'FEE',
        0,
        'Account status changed from ' || :OLD.status || ' to ' || :NEW.status
    );
END;
/

-- Prevent negative balances for non-loan accounts
CREATE OR REPLACE TRIGGER trg_prevent_negative_balance
BEFORE UPDATE OF balance ON accounts
FOR EACH ROW
WHEN (NEW.balance < 0 AND NEW.account_type != 'LOAN')
BEGIN
    RAISE_APPLICATION_ERROR(-20022, 'Non-loan accounts cannot have negative balance');
END;
/

-- Validate transaction amounts
CREATE OR REPLACE TRIGGER trg_validate_transaction
BEFORE INSERT ON transactions
FOR EACH ROW
BEGIN
    IF :NEW.amount <= 0 AND :NEW.transaction_type IN ('DEPOSIT', 'WITHDRAWAL', 'TRANSFER') THEN
        RAISE_APPLICATION_ERROR(-20023, 'Transaction amount must be positive');
    END IF;
END;
/

-- Update loan status when balance reaches zero
CREATE OR REPLACE TRIGGER trg_update_loan_status
AFTER UPDATE OF balance ON accounts
FOR EACH ROW
WHEN (NEW.account_type = 'LOAN' AND NEW.balance >= 0)
BEGIN
    UPDATE loans
    SET status = 'PAID',
        remaining_balance = 0
    WHERE account_id = :NEW.account_id;
END;
/