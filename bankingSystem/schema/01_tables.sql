/*
File: 01_tables.sql
Description: Core table definitions for banking system
*/

-- Customers table
CREATE TABLE customers (
    customer_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR2(50) NOT NULL,
    last_name VARCHAR2(50) NOT NULL,
    email VARCHAR2(100) UNIQUE NOT NULL,
    phone VARCHAR2(20),
    address VARCHAR2(200),
    date_of_birth DATE,
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL
);

-- Accounts table
CREATE TABLE accounts (
    account_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id NUMBER NOT NULL,
    account_type VARCHAR2(20) NOT NULL CHECK (account_type IN ('CHECKING', 'SAVINGS', 'LOAN', 'CREDIT')),
    account_number VARCHAR2(20) UNIQUE NOT NULL,
    balance NUMBER(15,2) DEFAULT 0 NOT NULL,
    open_date DATE DEFAULT SYSDATE NOT NULL,
    status VARCHAR2(10) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'CLOSED', 'FROZEN')),
    interest_rate NUMBER(5,2),
    CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Transactions table
CREATE TABLE transactions (
    transaction_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id NUMBER NOT NULL,
    transaction_type VARCHAR2(20) NOT NULL CHECK (transaction_type IN ('DEPOSIT', 'WITHDRAWAL', 'TRANSFER', 'INTEREST', 'FEE')),
    amount NUMBER(15,2) NOT NULL,
    transaction_date TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    description VARCHAR2(200),
    related_account_id NUMBER,
    status VARCHAR2(10) DEFAULT 'COMPLETED' CHECK (status IN ('COMPLETED', 'PENDING', 'FAILED', 'REVERSED')),
    CONSTRAINT fk_account FOREIGN KEY (account_id) REFERENCES accounts(account_id),
    CONSTRAINT fk_related_account FOREIGN KEY (related_account_id) REFERENCES accounts(account_id)
);

-- Loans table
CREATE TABLE loans (
    loan_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id NUMBER NOT NULL,
    principal_amount NUMBER(15,2) NOT NULL,
    interest_rate NUMBER(5,2) NOT NULL,
    term_months NUMBER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    monthly_payment NUMBER(15,2) NOT NULL,
    remaining_balance NUMBER(15,2) NOT NULL,
    status VARCHAR2(15) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'PAID', 'DEFAULTED', 'DELINQUENT')),
    CONSTRAINT fk_loan_account FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);