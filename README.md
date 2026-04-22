# Cost Development App (Salesforce)

Native Salesforce time tracking for **hybrid on-prem / commercial-style** labor, **rate cards**, and **ServiceNow ticket** references. Metadata targets API **62.0**.

## What is included (v1)

- **Global value sets**: Offering, Labor Pool, Job Role, Task Category.
- **Objects**: `Project__c` (CD Project), `Time_Entry__c` (CD Time Entry), `Rate_Card__c` (CD Rate Card).
- **User defaults**: `CD_Default_Job_Role__c`, `CD_Default_Labor_Pool__c` on User (optional; filled on insert by Apex when the time line leaves them blank). A lookup default project on User is not used—Salesforce blocks or rejects that pattern in many orgs; pick **Project** on each line or add a Screen Flow later.
- **Automation**: `Time_Entry_Before` trigger + `TimeEntryRateService` stamps `Rate_Applied__c` from the best matching rate card (offering from project + role + pool + work date). `Extended_Amount__c` is a formula (`Hours__c * Rate_Applied__c`).
- **Lightning app**: **Cost Development App** (`Cost_Development`).
- **Log Time UI (internal)**: Lightning **App Page** **`CD_Log_Time`** on tab **Log Time** inside the **Cost Development App** — same **`timeEntryPortal`** LWC (no separate website). After deploy and permission set assignment: **App Launcher** → **Cost Development App** → **Log Time** tab.
- **Experience Cloud form** (optional): same LWC can be placed on an Experience page; see [docs/experience-site-setup.md](docs/experience-site-setup.md). Assign **`Cost_Development_Experience_Logger`** to portal users.
- **Permission sets**: **Cost Development Admin**, **Cost Development Logger** (no Rate Card tab/object access), **Cost Development Experience Logger** (portal + `Account` read for labels; no Rate Card).

## Deploy

Prerequisites: [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) (`sf`) and an org (sandbox or scratch).

```bash
sf org login web --alias cd-dev --set-default
sf project deploy start --source-dir force-app --target-org cd-dev
sf apex run test --tests TimeEntryRateServiceTest --tests TimeEntryPortalControllerTest --target-org cd-dev --result-format human --code-coverage --wait 10
```

After deploy:

1. Assign **Cost Development Admin** or **Cost Development Logger** to pilot users.
2. Open **App Launcher** → **Cost Development App** → **Log Time** tab for the streamlined form (or use **Projects** / **CD Time Entries** tabs for standard lists).
3. Create **CD Rate Cards** (Admin) for each **Offering + Job Role + Labor Pool** with **Effective Start** (and optional **Effective End**).
4. Create **Accounts** (customers) and **CD Projects** (set **Offering** to match rate cards).
5. Log **CD Time Entries** (hours, category, role, pool, optional ServiceNow fields).

Add new picklist values (categories, roles, etc.) via **Setup → Picklist Value Sets** (global value sets).

## Repo layout

- `force-app/main/default/` — Salesforce DX metadata (`objects`, `globalValueSets`, `classes`, `triggers`, `applications`, `permissionsets`, `tabs`).

## Closed / disconnected environments

This package is **self-contained metadata and in-org Apex** only. It does **not** add:

- **HTTP callouts** (no `HttpRequest`, no callout-enabled Apex)
- **Named Credentials**, **Remote Site Settings**, or **CORS** entries for third-party hosts
- **Custom** LWCs or **static resources** that load fonts, scripts, or styles from **third-party** CDNs (the included **`timeEntryPortal`** uses **Lightning base components** and in-org APIs only)
- **External Services** integrations

Metadata files use the standard XML namespace string `http://soap.sforce.com/2006/04/metadata`; that is a **schema identifier**, not a runtime request to the internet.

The **Lightning Experience shell** (fonts, Lightning components, etc.) is loaded according to **Salesforce’s own disconnected / government cloud / private instance** packaging—outside the scope of this repo. Your platform team should confirm that org configuration (e.g. **My Domain**, release updates, any org-wide **CSP** or proxy rules) matches your closed-environment policy.

**ServiceNow Ticket URL** is optional **user-entered** data. Saving a URL does not call ServiceNow from Salesforce; if users **click** the link in the browser, that navigation is a client-side behavior—train users or adjust org/browser policy if outbound navigation must be blocked.

## Notes

- **Sharing**: `Time_Entry__c` is **Private** OWD (owner-based). **Logger** has no **View All** on time entries. Adjust sharing rules later for managers if needed.
- **Projects** use **Public Read/Write** OWD so teams can select projects; tighten if your org requires private projects.
- **Screen Flow** for the utility bar was deferred for v1; use list views, standard create forms, or the **Experience** form in [docs/experience-site-setup.md](docs/experience-site-setup.md).
- **Experience site metadata** (`Network`, `ExperienceBundle`) is created in the org UI then optionally **retrieved** into git—see the doc’s “Version-control the site” section—because names and templates vary by org.
