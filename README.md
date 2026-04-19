# 1Rad Clinical Hub: Database Project

## Overview
This project contains the master schema and DDL/DML scripts for the 1Rad Clinical Hub database. It supports a multi-facility environment with advanced identity management and clinical mission control features.

## Project Structure
- **/schema**: Core DDL scripts for baseline creation and ongoing migrations.
  - `registration.sql`: Master Master Create Script (v2.0) for new environments.
  - **/DDL Scripts**: Specific incremental updates (Users, Roles, Missions).
- **/data**: DML scripts for seeding lookup tables and system roles.
- **/rollback**: Inversion scripts for safe schema reversion and disaster recovery.

## Key Architecture Features
1. **Multi-Role Authorization**: Uses a many-to-many bridge (`UserHospitalRoles`) between staff mappings and roles.
2. **Mission Command Hub**: Unified schema for `Patients` (with sequential `PTID`), `Referrers`, and `Appointments`.
3. **Security Persistence**: Built-in support for `OTPVerifications` and `RefreshTokens`.
4. **Clinical Context**: Extended metadata for hospital registration (PAN, GSTIN) and user credentials (License, Degree).

## Getting Started
To provision a new database:
1. Execute `schema/registration.sql` to build the core infrastructure.
2. Execute `data/dml_userroles.sql` to seed the clinical roles.

## Maintenance & Recovery
Always use the corresponding script in the `/rollback` directory before attempting to re-run a DDL script that has failed or needs adjustment.