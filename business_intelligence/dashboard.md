# Business Intelligence Dashboards

These dashboards help different users understand how the Digital ID system is being used.  
All the measurements (KPIs) used here are listed in:  
➡️ `/business_intelligence/kpi_definitions.md`

---

## 1. Strategic Security Dashboard (Executive Level)

**Users:** National leaders (Directors, Chief Privacy Officer)  
**Purpose:** Quickly check if the system is being used safely and correctly across the whole country.

| Report / Metric | Visualization | Data Source | Meaning |
|------------------|--------------|-------------|---------|
| **National Compliance Score (KPI-01)** | Gauge / Single Number | `ACCESS_AUDIT_LOG` | Shows the percentage of access attempts that were allowed. Should be above **98%**. |
| **High-Severity Violations** | Red Alert Counter | `PRIVACY_VIOLATIONS` | Shows how many serious security issues happened in the last 30 days. |
| **Agency Risk Ranking** | Bar Chart | `ACCESS_AUDIT_LOG`, `PRIVACY_VIOLATIONS` | Ranks agencies from safest to most risky based on violation frequency. |
| **Access Trend (Allowed vs Denied)** | Line Chart | `ACCESS_AUDIT_LOG` | Shows changes in access behavior. Sudden spikes may indicate misuse. |

---

## 2. Operational Dashboard (Manager Level)

**Users:** Agency Managers, Internal Auditors  
**Purpose:** Monitor employees inside an agency and ensure they follow rules.

| Report / Metric | Visualization | Data Source | Meaning |
|------------------|--------------|-------------|---------|
| **Top 5 Violators** | Ranked Table | `ACCESS_AUDIT_LOG` | Shows employees with the most unauthorized access attempts. |
| **Access by Data Category** | Pie / Donut Chart | `ACCESS_AUDIT_LOG` | Checks if employees are only accessing data their agency is supposed to use (e.g., RRA = Financial data). |
| **After-Hours Access Attempts** | Heatmap | `ACCESS_AUDIT_LOG` | Shows how many times employees accessed data outside working hours (06:00–20:00). |
| **Permissions Expiring Soon** | List / Table | `ACCESS_PERMISSIONS` | Shows permissions that will expire within 7 days so managers can renew them if needed. |

---

## 3. Citizen Transparency Dashboard

**Users:** Citizens  
**Purpose:** Show citizens exactly how their personal data is being accessed.

| Report / Metric | Visualization | Data Source | Meaning |
|------------------|--------------|-------------|---------|
| **Total Accesses to My Record** | Single Number | `ACCESS_AUDIT_LOG` (filtered) | Shows how many times agencies viewed the citizen’s data. |
| **Active Permissions for My Data** | Table | `ACCESS_PERMISSIONS` | Shows which agencies currently have access and when that access expires. |
| **Full Audit History** | Table | `ACCESS_AUDIT_LOG` | A complete list of every access attempt — who accessed the data, when, and whether it was allowed. |
| **Unauthorized Attempts on My Data** | Notification / List | `PRIVACY_VIOLATIONS` | Shows all denied or suspicious attempts made on the citizen’s data. |

---
