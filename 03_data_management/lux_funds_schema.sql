CREATE TABLE lux_funds (
    id INT NOT NULL,
    fund_name VARCHAR(30) NOT NULL,
    subfund_name VARCHAR(30) NOT NULL,
    account_number CHAR(34) NOT NULL,
    auditor VARCHAR(30) NOT NULL,
    beginning_service_date DATE,
    NAV_date DATE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    previous_amount DECIMAL(10,2) NOT NULL,
    estimated_amount DECIMAL(10,2) NOT NULL,
    importance VARCHAR(10),
    CONSTRAINT pk_funds PRIMARY KEY (id)
);
