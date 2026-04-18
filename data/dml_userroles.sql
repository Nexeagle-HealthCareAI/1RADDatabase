/* =========================================================
   Seed Roles
   ========================================================= */
IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = 'AdminDoctor')
    INSERT INTO dbo.Roles (RoleName) VALUES ('AdminDoctor');

IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = 'Admin')
    INSERT INTO dbo.Roles (RoleName) VALUES ('Admin');

IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = 'Doctor')
    INSERT INTO dbo.Roles (RoleName) VALUES ('Doctor');

IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = 'Technician')
    INSERT INTO dbo.Roles (RoleName) VALUES ('Technician');

IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = 'Receptionist')
    INSERT INTO dbo.Roles (RoleName) VALUES ('Receptionist');

IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = 'Accountant')
    INSERT INTO dbo.Roles (RoleName) VALUES ('Accountant');
GO