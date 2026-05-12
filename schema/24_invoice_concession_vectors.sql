-- Add Triple-Vector Deduction Tracking to Invoices
ALTER TABLE Invoices ADD CentreDiscount DECIMAL(18, 2) NOT NULL DEFAULT 0;
ALTER TABLE Invoices ADD ReferrerDiscount DECIMAL(18, 2) NOT NULL DEFAULT 0;
ALTER TABLE Invoices ADD InstitutionalDeduction DECIMAL(18, 2) NOT NULL DEFAULT 0;
