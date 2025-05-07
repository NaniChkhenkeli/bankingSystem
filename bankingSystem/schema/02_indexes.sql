/*
File: 02_indexes.sql
Description: Performance optimization indexes
*/

-- Account indexes
CREATE INDEX idx_account_customer ON accounts(customer_id);
CREATE INDEX idx_account_number ON accounts(account_number);
CREATE INDEX idx_account_type_status ON accounts(account_type, status);

-- Transaction indexes
CREATE INDEX idx_transaction_account ON transactions(account_id);
CREATE INDEX idx_transaction_date ON transactions(transaction_date);
CREATE INDEX idx_transaction_type_status ON transactions(transaction_type, status);

-- Loan indexes
CREATE INDEX idx_loan_account ON loans(account_id);
CREATE INDEX idx_loan_status ON loans(status);
CREATE INDEX idx_loan_end_date ON loans(end_date);