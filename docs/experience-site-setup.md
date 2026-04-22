# Experience Cloud: Cost Development time portal

This guide wires the **`timeEntryPortal`** LWC into an authenticated **Experience Cloud** site so users get a simple form while inserts still hit **`Time_Entry__c`** (including the `Time_Entry_Before` trigger and rate stamping).

**Internal Salesforce:** the same component is already on the **Cost Development App** tab **Log Time** (Lightning page **`CD_Log_Time`**) after you deploy this repo—no Experience site required for that path.

## Prerequisites

- **Digital Experiences** enabled for the org (and appropriate **Experience Cloud** licenses for your member model).
- Metadata from this repo deployed (`Project__c`, `Time_Entry__c`, `Rate_Card__c`, Apex, LWC).
- Permission sets assigned as described below.

## 1. Create the Experience site (UI)

1. From Setup, open **Digital Experiences** → **All Sites** → **New**.
2. Choose a starter (for example **Build Your Own (LWR)** or **Customer Service**). Either works with the LWC target `lightningCommunity__Page`.
3. Name the site (example: **Cost Development Portal**). Note the **URL path prefix** (e.g. `costdev`) — that becomes part of the login URL.
4. Under **Administration** / **Login & Registration**, configure **authenticated** access only (do **not** rely on guest users to create time entries).
5. If internal employees should use their **Salesforce user** identity, enable options such as **Allow members to log in with their Salesforce credentials** / **Allow internal users to log in** (wording varies by release). Align with your security team for the closed environment.

## 2. Publish access (profiles / permission sets)

1. In Experience Builder, **Settings** → **General** (or **Administration** → **Members**) and confirm which **profile** your members use (clone of Customer Community User, Partner Community User, etc.).
2. For each user who should use the portal, assign the permission set **`Cost_Development_Experience_Logger`** (and optionally **`Cost_Development_Logger`** for internal Lightning app use).
3. On the **member profile** (or supplemental permission sets), ensure users have at least **read** access to **Account** so the project picker can show **Account** names in labels (`Account__r.Name` in Apex respects field-level security for the running user).
4. On the **Experience Cloud site’s guest/member profile** (as applicable), ensure **Apex class access** includes **`TimeEntryPortalController`** if you are not using permission-set-only class access for that profile model. Prefer **permission sets** for class access.

## 3. Add the “Log time” page in Experience Builder

1. Open **Experience Builder** for the site.
2. **Pages** → **New** → **Standard** page (full width recommended). Name it **Log Time**; the path will be something like `/log-time` (Builder shows the exact URL).
3. From the component palette, under **Custom**, drag **CD Time Entry Portal** (`timeEntryPortal`) onto the page (single-column layout is fine).
4. **Publish** the site.

Optional: set **Log Time** as the **default home** page under **Settings** → **General** so users land on the form.

## 4. Version-control the site (optional)

Experience **Network** and **Experience Bundle** metadata are org-specific and template-dependent. After the site is stable, retrieve them into this repo so sandboxes stay aligned, for example:

```bash
sf project retrieve start -m "Network:Your_Network_API_Name"
```

If your org uses **Digital Experience** bundles, retrieve the corresponding **`ExperienceBundle`** / **`DigitalExperience`** metadata types your team standardizes on (names match what appears in **Setup → Digital Experiences**).

## 5. Verify

1. Log in to the Experience site as a member user.
2. Open **Log Time**, complete the form, **Submit**.
3. In the internal org (or same org), open the created **`Time_Entry__c`**: **Owner** should be the running user, **`Rate_Applied__c`** set when a matching **`Rate_Card__c`** exists.

## Closed environment note

The portal uses **Lightning base components**, **UI API**, and **Apex** only—no extra callouts or third-party CDNs. Assets are served from your **Salesforce instance** (same as the rest of Lightning / Experience).
