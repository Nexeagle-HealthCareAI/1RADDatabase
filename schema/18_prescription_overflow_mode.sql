/* 
 * SCHEMA EVOLUTION: PRESCRIPTION PROTOCOL OVERFLOW BEHAVIOR
 * Adds support for multi-page letterhead binding logic (REUSE vs BLANK).
 */

IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[PrescriptionProtocols]') 
    AND name = 'OverflowBackgroundMode'
)
BEGIN
    ALTER TABLE [dbo].[PrescriptionProtocols] 
    ADD [OverflowBackgroundMode] NVARCHAR(50) NOT NULL DEFAULT 'REUSE';
    
    PRINT 'STRATEGIC PATCH SUCCESS: [OverflowBackgroundMode] column integrated.';
END
ELSE
BEGIN
    PRINT 'ARCHITECTURAL NOTICE: [OverflowBackgroundMode] column already exists in current schema context.';
END
GO
