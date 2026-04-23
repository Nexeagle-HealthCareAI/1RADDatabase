IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PrescriptionProtocols]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[PrescriptionProtocols] (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        [DoctorId] UNIQUEIDENTIFIER NOT NULL,
        [HospitalId] UNIQUEIDENTIFIER NOT NULL,
        [HeaderMargin] DECIMAL(18, 2) NOT NULL DEFAULT 50.00,
        [LeftMargin] DECIMAL(18, 2) NOT NULL DEFAULT 20.00,
        [RightMargin] DECIMAL(18, 2) NOT NULL DEFAULT 20.00,
        [BottomMargin] DECIMAL(18, 2) NOT NULL DEFAULT 30.00,
        [FontSize] INT NOT NULL DEFAULT 14,
        [FontColor] NVARCHAR(50) NOT NULL DEFAULT '#1e293b',
        [FontFamily] NVARCHAR(100) NOT NULL DEFAULT 'Inter',
        [LetterheadBlobUrl] NVARCHAR(MAX) NULL,
        [CreatedAt] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        
        CONSTRAINT [FK_PrescriptionProtocols_Users] FOREIGN KEY ([DoctorId]) REFERENCES [dbo].[Users] ([UserId]) ON DELETE CASCADE,
        CONSTRAINT [FK_PrescriptionProtocols_Hospitals] FOREIGN KEY ([HospitalId]) REFERENCES [dbo].[Hospitals] ([HospitalId]) ON DELETE CASCADE
    );

    CREATE UNIQUE INDEX [UIX_PrescriptionProtocols_Doctor_Hospital] 
    ON [dbo].[PrescriptionProtocols] ([DoctorId], [HospitalId]);
END
GO
