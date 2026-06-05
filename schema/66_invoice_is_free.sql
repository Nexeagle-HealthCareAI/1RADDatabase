-- Free test flag (Scenario 07): keep the bill but zero payable/income/commission.
-- Lets reports tell a genuine free test apart from an ordinary 100% discount.
IF COL_LENGTH('dbo.Invoices', 'IsFree') IS NULL
BEGIN
    ALTER TABLE [dbo].[Invoices] ADD [IsFree] BIT NOT NULL DEFAULT 0;
END
GO
