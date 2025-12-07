# Business Intelligence Requirements

## Overview

The BI layer transforms audit data into actionable insights for three stakeholder groups:

1. **Government Oversight** - Monitor compliance and violations
2. **Agency Administrators** - Track employee access patterns
3. **Citizens** - View who accessed their data

---

## BI Objectives

| Objective | Success Metric |
|:---|:---|
| **Transparency** | 100% of access attempts logged and reportable |
| **Compliance Monitoring** | Agency compliance rate > 95% |
| **Early Warning** | Alert on violations within 5 minutes |
| **Audit Trail** | Immutable logs with 7-year retention |

---

## Stakeholder Needs

### Government Oversight (NISR, OAG)

**Key Reports:**
- Monthly compliance report (all agencies ranked)
- High-risk employee list (multiple violations)
- Data access heatmap (patterns by time/agency)
- Full audit trail export (CSV)

### Agency Administrators (RRA, MINISANTE, RIB)

**Key Reports:**
- Agency dashboard (compliance rate, active employees)
- Employee activity report (top 10 most active)
- Permission status (expiry dates)
- Denied access summary (unauthorized attempts)

### Citizens

**Key Reports:**
- My data access history (timeline)
- Agencies with access (permissions)
- Recent activity alerts (last 7 days)

---

## Alert Configuration

### Critical Alerts (Email + SMS)

| Alert | Trigger | Recipients |
|:---|:---|:---|
| High-Severity Violation | `severity = 'HIGH'` | Security Team, Agency Head |
| After-Hours Bulk Access | > 50 attempts (8PM-6AM) | NISR, IT Security |
| Expired Permission Used | Access with expired permission | Legal, Agency Admin |

### Warning Alerts (Email Only)

| Alert | Trigger | Recipients |
|:---|:---|:---|
| Permission Expiring Soon | < 30 days to expiry | Agency Admin |
| Low Compliance Rate | < 85% | Agency Head, Oversight |
| Unusual Access Pattern | > 3x daily average | Supervisor |

---

## Reporting Schedule

**Daily (Automated):**
- Overnight activity summary (6 AM)
- Violation status report (9 AM)

**Weekly (Automated):**
- Agency compliance scorecard (Monday 8 AM)
- Top 10 active employees (Friday 5 PM)

**Monthly (Manual):**
- Executive compliance report (5th of month)
- Citizen access statistics (10th of month)
- Permission expiry forecast (15th of month)

---

## Data Retention

| Data Type | Retention | Archive Strategy |
|:---|:---|:---|
| Access Audit Logs | 7 years | Partition by year after 1 year |
| Privacy Violations | Permanent | Never delete |
| DML Audit Logs | 1 year | Delete via `sp_archive_old_logs()` |

---

## Technical Implementation

**Current (Capstone):**
- SQL queries with window functions
- Manual report generation
- Test data: 100-200 citizens, 500+ audit logs

**Future (Production):**
- Oracle APEX or Power BI dashboards
- Automated email alerts
- Citizen web/mobile portal
- Real-time monitoring

---

