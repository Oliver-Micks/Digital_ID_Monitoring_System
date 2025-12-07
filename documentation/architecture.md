# System Architecture

## Overview
The Digital ID Data Privacy and Access Monitoring System is built on Oracle Database 21c with a multi-tier architecture designed for security, scalability, and maintainability.

## Architecture Diagram
┌─────────────────────────────────────────────────────────────┐
│ CITIZEN INTERFACE LAYER │
│ (Reports, Transparency Dashboards, Self-Service Portal) │
└───────────────────────────┬─────────────────────────────────┘
│
┌───────────────────────────▼─────────────────────────────────┐
│ APPLICATION LAYER │
│ (PL/SQL Procedures, Functions, Packages, Business Logic) │
└───────────────────────────┬─────────────────────────────────┘
│
┌───────────────────────────▼─────────────────────────────────┐
│ DATABASE LAYER │
│ (Tables, Indexes, Views, Triggers, Security Rules) │
└───────────────────────────┬─────────────────────────────────┘
│
┌───────────────────────────▼─────────────────────────────────┐
│ INFRASTRUCTURE LAYER │
│ (Oracle 21c PDB, Tablespaces, Storage, Network) │
└─────────────────────────────────────────────────────────────┘


## Components Description

### 1. Infrastructure Layer
- **Oracle Database 21c PDB:** `Mon_27119_Olivier_DigitalID_db`
- **Tablespaces:**
  - `tbs_data`: Main data storage (200MB initial, autoextend)
  - `tbs_idx`: Index storage (100MB initial, autoextend)
  - `temp_digital`: Temporary workspace (100MB)
- **Users:**
  - `olivier_admin`: PDB administrator (SYSDBA equivalent for PDB)
  - `digital_id_user`: Application user with ALL PRIVILEGES
- **Configuration:**
  - Archive logging enabled for audit compliance
  - SGA: 512MB, PGA: 256MB
  - Automatic maintenance tasks enabled

### 2. Database Layer
#### Core Tables (6)
1. **CITIZENS:** Master citizen registry (100+ records)
2. **GOVERNMENT_AGENCIES:** Authorized entities (RRA, MINISANTE, etc.)
3. **AGENCY_EMPLOYEES:** System users with credentials
4. **ACCESS_PERMISSIONS:** Authorization rules
5. **ACCESS_AUDIT_LOG:** Immutable activity log
6. **PRIVACY_VIOLATIONS:** Security incident tracking

#### Security Implementation
- **Primary Keys:** All tables have numeric PKs
- **Foreign Keys:** Enforce referential integrity
- **Check Constraints:** Validate data categories, statuses
- **Unique Constraints:** Prevent duplicates (phones, usernames)
- **Default Values:** Auto-populate timestamps, statuses

### 3. Application Layer (PL/SQL)
#### Types of PL/SQL Objects
1. **Stored Procedures:** For data manipulation and business logic
2. **Functions:** For calculations and validations
3. **Packages:** For organizing related procedures
4. **Triggers:** For automatic auditing and enforcement
5. **Cursors:** For batch processing of data

#### Key PL/SQL Components
- **Access Validation Engine:** Checks permissions before granting access
- **Audit Logging System:** Automatically records all activities
- **Violation Detection:** Identifies suspicious patterns
- **Reporting Engine:** Generates citizen transparency reports
- **Data Quality Checks:** Ensures data integrity

### 4. Citizen Interface Layer (Conceptual)
While this capstone focuses on database implementation, the system is designed to support:

#### Future Interfaces
1. **Citizen Self-Service Portal:**
   - View who accessed their data
   - Request access reports
   - Report suspicious activities

2. **Agency Dashboard:**
   - Monitor employee access patterns
   - Generate compliance reports
   - Manage permissions

3. **Administrator Console:**
   - System configuration
   - User management
   - Security monitoring

## Data Flow
Employee requests access to citizen data
↓

System validates: Employee → Agency → Permission → Expiry
↓

If valid → Log access (YES) → Return data
↓

If invalid → Log access (NO) → Create violation → Block access
↓

Citizen can later view all access attempts in their audit trail

text

## Security Architecture
### Defense in Depth
1. **Authentication:** Username/password for employees
2. **Authorization:** Agency-based permission checking
3. **Auditing:** Complete activity logging
4. **Validation:** Data type and constraint checking
5. **Encryption:** Future enhancement for sensitive data

### Principle of Least Privilege
- Employees only see data their agency is authorized to access
- Each agency has specific data category permissions
- No universal admin access in production

## Performance Considerations
### Indexing Strategy
- Primary keys indexed automatically
- Foreign keys indexed manually
- Frequently queried columns indexed
- Large text columns not indexed

### Query Optimization
- Use WHERE clauses to limit result sets
- Proper JOIN conditions for efficient queries
- Aggregate functions for summary data
- Partitioning ready for future scaling

## Scalability Design
### Current Implementation
- 100 citizens (demonstration scale)
- 7 agencies (realistic sample)
- 21 employees (3 per agency)
- Designed for easy scaling

### Future Scalability
- Horizontal scaling: Add more PDBs
- Vertical scaling: Increase resources
- Partitioning: By district or date
- Caching: Frequently accessed data

## Backup and Recovery
### Built-in Features
- Archive logging enabled
- Regular backup capability
- Point-in-time recovery possible
- Data export/import scripts included

### Disaster Recovery
- Database scripts recreate entire structure
- Sample data scripts repopulate test data
- Documentation enables quick restoration

## Compliance Features
### GDPR Principles Implemented
1. **Right to Access:** Citizens can see who accessed their data
2. **Right to be Informed:** Transparent logging
3. **Data Minimization:** Only necessary data collected
4. **Storage Limitation:** Permissions have expiry dates
5. **Integrity and Confidentiality:** Security measures in place

### Audit Requirements Met
- Immutable audit trail
- Tamper-proof logging
- Complete activity history
- Automated violation detection

## Technology Stack
| **Component** | **Technology** | **Version** |
|---------------|----------------|-------------|
| Database | Oracle Database | 21c |
| Development | PL/SQL | 21c |
| IDE | SQL Developer / VS Code | Latest |
| Version Control | Git / GitHub | Latest |
| Documentation | Markdown | Standard |

## Deployment Architecture
### Development Environment
- Local Oracle 21c installation
- SQL Developer for database access
- VS Code for script development
- Git for version control

### Production Readiness
- Script-based deployment
- Environment-agnostic configuration
- Comprehensive error handling
- Rollback capability

## Monitoring and Maintenance
### Built-in Monitoring
- Row counts validation
- Constraint checking
- Performance metrics
- Error logging

### Maintenance Procedures
- Permission expiry management
- Audit log archiving
- User account management
- Data quality checks