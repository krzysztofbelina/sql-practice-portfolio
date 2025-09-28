-- Schema: custody_nav (external custody source for reconciliation)
-- Purpose: companion dataset to lux_funds for multi-key joins in reconciliation use-cases.
-- Join keys: (fund_name, nav_date, account_number)

CREATE TABLE custody_nav (
    id               INT PRIMARY KEY,
    fund_name        VARCHAR(30)   NOT NULL,
    subfund_name     VARCHAR(30)   NOT NULL,
    account_number   CHAR(34)      NOT NULL,
    nav_date         DATE          NOT NULL,
    amount           NUMERIC(10,2) NOT NULL,
    previous_amount  NUMERIC(10,2) NOT NULL,
    estimated_amount NUMERIC(10,2) NOT NULL,
    source           VARCHAR(20)   NOT NULL DEFAULT 'Custody'
);

CREATE INDEX idx_custody_nav_key ON custody_nav (fund_name, nav_date, account_number);
