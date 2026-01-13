# Domain and Data Modeling Specification

**Project:** Municipal Service Issue Tracker (MunServ)  
**Version:** 0.2 (Draft)  
**Last Updated:** December 2024  
**Status:** Discovery Phase

---

## 1. Overview

This document defines the domain model for a community-based municipal service issue reporting system. The system allows community members to report infrastructure issues (potholes, broken lights, water leaks, etc.) via a mobile application, with management and oversight through a web-based administration interface.

### 1.1 Design Principles

- **Start simple, design for expansion**: MVP focuses on core reporting flow; hierarchy and advanced features come later
- **High-trust communities**: Members are vouched for by administrators to reduce bad actors
- **Heat-based prioritization**: Issue urgency determined algorithmically by time open + report count
- **Pod isolation**: Each deployment is independent with its own infrastructure and data

---

## 2. Organizational Hierarchy

The system uses a hierarchical structure to manage communities at various scales. The metaphor of a fleet helps clarify relationships:

```
Central Authority (Fleet Command)
    └── Pod (Ship / Battle Group)
            └── Sector Group (Ship Areas) [optional tier]
                    └── Sector (Individual Area / Ward / Community)
                            └── Members (Crew)
```

### 2.1 Central Authority (Fleet Command)

**Purpose:** The organization providing and maintaining the system.

**Responsibilities:**

- System-wide maintenance and enhancements
- Cloud infrastructure setup for new pods
- Technical support and issue escalation
- Billing and cost management

**Access:**

- Can access any pod for debugging/investigation (temporary, audited access)
- No day-to-day involvement in pod operations

**Users:** Technical staff, support personnel, system administrators

---

### 2.2 Pod

**Purpose:** An independent deployment serving one or more communities.

**Characteristics:**

- Own cloud infrastructure (compute, database, storage)
- Own configuration and customizations
- Isolated from other pods
- Can have unique workflows and reporting structures

**Example Configurations:**
| Pod Type | Description | Typical Structure |
|----------|-------------|-------------------|
| Metro Pod | Large city with many wards | Metro → Region → Ward (deep hierarchy) |
| Town Pod | Single town with neighborhoods | Town → Neighborhood (flat) |
| Rural Pod | Collection of farms/small holdings | Area → Farm clusters (minimal hierarchy) |
| Multi-town Pod | Group of small towns | Town A, Town B, Town C (parallel sectors) |

**Roles:**

- **Pod Chief**: Full responsibility for pod setup, structure, administrators, reporting, and communication with Central Authority
- **Pod Administrator**: Manages communication with sectors/sector groups, generates reports, handles escalations (can have scoped access to specific sectors)

---

### 2.3 Sector Group (Optional Tier)

**Purpose:** An intermediate grouping when a pod contains many sectors. Acts as a "mini-pod" for management purposes.

**When Used:**

- Large metro areas with dozens of wards
- When regional coordination is needed between sectors
- To reduce span of control for Pod administrators

**Roles:**

- **Sector Group Chief**: Sets up the sector group structure, manages administrators, handles reporting and communication to pod level
- **Sector Group Administrator**: Manages sectors within the group, coordinates with Sector Chiefs

---

### 2.4 Sector

**Purpose:** The primary operational unit where issues are reported and managed. Represents a ward, community, small town, or defined geographic area.

**Characteristics:**

- Has defined geographic boundaries (see Section 5)
- Contains members who live/work in the area
- Has its own administrator team
- Issues are assigned to sectors based on location

**Roles:**

- **Sector Chief**: Sets up sector structure, creates administrators, has final responsibility for sector operations, communicates with Sector Group or Pod level
- **Sector Administrator**: Approves/rejects issues, manages members and community administrators, generates sector reports, changes issue states
- **Community Administrator**: Trusted member who can vouch for new members, verify/confirm reported issues and fixes, participate in admin coordination chat

---

### 2.5 Members

**Purpose:** Community residents who report and view issues.

**Requirements to Join:**

- Email address (for authentication and notifications)
- Phone number (for contact purposes)
- Address within the sector (proves community residency)
- Approved by a Sector Administrator

**Capabilities:**

- Report issues via mobile app (with photos)
- View issues in their community
- View status updates on reported issues
- View shared reports from administrators

**Restrictions:**

- Mobile app only (no web admin access)
- Can be flagged/warned for misuse (privately, not publicly visible)

---

### 2.6 Member Registration Flow

**Overview:** Members register through the web portal to avoid SMS costs. Admin approval is required before access is granted.

**Registration Steps:**

```
1. REGISTER: Member visits web portal → fills registration form
2. PENDING:  System creates member with "Pending Approval" status
3. REVIEW:   Sector Admin reviews registration details
4. APPROVE:  Admin approves → system generates temp password → email sent
5. LOGIN:    Member downloads mobile app → logs in with email + temp password
6. PASSWORD: Member must change password on first login
7. PIN:      Member sets up 4-digit PIN for quick access
8. BIOMETRIC: (Optional) Member enables fingerprint/face login
```

**Registration Form Fields:**
- First name, Surname
- Email address (will be username)
- Phone number (for contact)
- Address (street address)
- Location (GPS coordinates - auto-captured)
- Sector (dropdown selection)

**State Diagram:**

```
[Web Registration]          [Admin Review]           [Member Access]
       │                          │                        │
       ▼                          ▼                        ▼
┌──────────────┐           ┌─────────┐            ┌────────────────┐
│ Registration │───────────│ Pending │────approve─│ Active Member  │
│    Form      │           │ Approval│            │ (email sent)   │
└──────────────┘           └─────────┘            └────────────────┘
                                │                        │
                                │reject                  │
                                ▼                        ▼
                           [Deleted]              [Mobile App Login]
```

**Email Notification:**
On approval, system sends welcome email containing:
- Login credentials (email + temporary password)
- Link to download mobile app
- Password requirements for first login

---

### 2.7 Member Status

Members have the following status states:

| Status | Description | Can Login | Transitions To |
|--------|-------------|-----------|----------------|
| **Pending Approval** | Registration submitted, awaiting admin review | No | Active, Deleted |
| **Active** | Approved member, full app access | Yes | Suspended, Deleted |
| **Suspended** | Temporarily blocked by admin | No | Active, Deleted |
| **Deleted** | Permanently removed (terminal state) | No | - |

**State Transition Rules:**
- **Pending → Active**: Admin approves registration
- **Pending → Deleted**: Admin rejects registration
- **Active → Suspended**: Admin suspends for policy violation
- **Suspended → Active**: Admin reinstates member
- **Any → Deleted**: Admin permanently removes member

---

## 3. Role Summary Matrix

| Role                       | Scope               | Key Permissions                              |
| -------------------------- | ------------------- | -------------------------------------------- |
| Central Authority Staff    | System-wide         | Debug access to pods, system maintenance     |
| Pod Chief                  | Entire pod          | Full pod setup, create admins, all reports   |
| Pod Administrator          | Pod (may be scoped) | Manage sectors, reports, escalations         |
| Sector Group Chief         | Sector group        | Setup group structure, manage group admins   |
| Sector Group Administrator | Sector group        | Manage sectors in group                      |
| Sector Chief               | Single sector       | Setup sector, create admins, final authority |
| Sector Administrator       | Single sector       | Approve issues, manage members, reports      |
| Community Administrator    | Single sector       | Vouch members, verify issues/fixes           |
| Member                     | Single sector       | Report issues, view issues and reports       |

**Note:** A person can hold multiple roles. An administrator can also be a member in their own sector. Someone could be Sector Chief in one sector and a regular member in another.

---

## 4. Issue Lifecycle

### 4.1 States

```
┌──────────┐     ┌───────────┐     ┌─────────────┐     ┌───────┐
│ REPORTED │ ──► │ CONFIRMED │ ──► │ IN PROGRESS │ ──► │ FIXED │
└──────────┘     └───────────┘     └─────────────┘     └───────┘
      │                │                  │                │
      ▼                ▼                  ▼                ▼
┌──────────┐     ┌──────────┐       ┌──────────┐    ┌──────────┐
│ REJECTED │     │ REJECTED │       │ REJECTED │    │ REOPENED │
└──────────┘     └──────────┘       └──────────┘    └──────────┘
                                                          │
                                                          ▼
                                                   (back to CONFIRMED)
```

| State           | Description                                            | Who Sets It                                        |
| --------------- | ------------------------------------------------------ | -------------------------------------------------- |
| **Reported**    | Initial state when member submits issue                | System (automatic)                                 |
| **Confirmed**   | Issue verified as legitimate                           | Community Admin confirms, or Sector Admin approves |
| **In Progress** | Work is being done to fix                              | Sector Admin                                       |
| **Fixed**       | Issue has been resolved                                | Sector Admin                                       |
| **Rejected**    | Invalid report (spam, wrong location, duplicate, etc.) | Sector Admin (manual); AI in future                |
| **Reopened**    | Fix was inadequate or issue recurred                   | Community Admin when verifying fix                 |

### 4.2 State Transition Rules

- **Reported → Confirmed**: When Community Admin verifies the issue exists, or Sector Admin approves
- **Reported → Rejected**: Sector Admin determines issue is invalid
- **Confirmed → In Progress**: Sector Admin marks work as started
- **Confirmed → Rejected**: Sector Admin determines issue should not be pursued
- **In Progress → Fixed**: Sector Admin marks as complete
- **In Progress → Rejected**: Sector Admin (edge case - discovered invalid during work)
- **Fixed → Reopened**: Community Admin verifies and finds issue not properly resolved
- **Reopened → Confirmed**: Automatic (goes back into the queue)

### 4.3 Duplicate Handling

Multiple members can report the same issue. This is expected and beneficial:

- Each additional report adds to the issue's "heat"
- Reports are linked to the original issue, not created as separate issues
- All reporters receive updates when status changes

**MVP Approach:** Manual linking by Sector Admin  
**Future:** AI-assisted duplicate detection based on location + issue type + photo analysis

### 4.4 Heat Algorithm

Heat represents urgency/priority. Higher heat = more attention needed.

**Heat Factors:**

1. **Time Open**: The longer an issue remains unresolved, the hotter it gets
2. **Report Count**: More people reporting the same issue increases heat
3. **Issue Type**: Some types may have inherent base heat (e.g., sewage leak > pothole)

**Formula (to be refined):**

```
Heat = (Base_Type_Heat) + (Days_Open × Time_Factor) + (Report_Count × Report_Factor)
```

**MVP Approach:** Simple calculation, tunable per pod  
**Future:** Machine learning to optimize factors based on resolution patterns

---

## 5. Geographic Model

### 5.1 Boundary Definition

Each sector has defined geographic boundaries. Issues are assigned to sectors based on the GPS coordinates from the photo.

**Options to Explore:**
| Method | Pros | Cons |
|--------|------|------|
| Polygon (GeoJSON) | Precise, handles irregular shapes | Complex to set up |
| Bounding box | Simple | Only works for rectangular areas |
| Radius from center | Very simple | Only works for roughly circular areas |
| Municipality data | Uses existing boundaries | May not match community definitions |

**MVP Approach:** Start with simple bounding box or polygon. Sector Chief defines boundaries during setup.

### 5.2 Location-Based Routing

- Issue is assigned to sector based on photo GPS coordinates
- If coordinates fall outside all sectors: flag for manual assignment
- If coordinates fall in overlapping sectors: assign to member's home sector

### 5.3 Cross-Sector Issues

**Current Decision:** Each sector handles its own issues independently.

**Future Consideration:** Issues near sector boundaries may affect multiple communities. Options:

- Visible to both sectors, owned by one
- Shared ownership with coordination
- Escalate to Sector Group level

---

## 6. Issue Types

### 6.1 Initial Categories

| Category              | Description                                      |
| --------------------- | ------------------------------------------------ |
| Pothole / Road Damage | Holes, cracks, collapsed sections of road        |
| Water Leak            | Leaking municipal water pipes or mains           |
| Sewerage Leak         | Leaking or overflowing sewage infrastructure     |
| Broken Traffic Light  | Non-functional or malfunctioning traffic signals |
| Broken Street Light   | Non-functional street lighting                   |
| Illegal Dumping       | Unauthorized waste disposal                      |
| Illegal Occupation    | Unauthorized structures or land use              |
| Graffiti              | Vandalism via paint/markers                      |
| Infrastructure Damage | General damage to municipal infrastructure       |

### 6.2 Extensibility

- Categories are configurable per pod
- Sector Groups or Sectors may request additional categories
- Each category can have metadata fields (future: materials needed, estimated cost, etc.)

### 6.3 Priority

Priority is determined by heat, not manually set. This removes subjective bias and ensures consistent treatment.

---

## 7. Photos and Evidence

### 7.1 Requirements

| Requirement       | Details                                                       |
| ----------------- | ------------------------------------------------------------- |
| Photos per issue  | 1 to 5 photos per report                                      |
| Required metadata | GPS coordinates, date/time (embedded in photo or from device) |
| Capture method    | Must be taken through the app (no gallery uploads for MVP)    |
| Timeliness        | Photo must be recent (within X hours - configurable)          |

### 7.2 Additional Photos

- Other members reporting the same issue add their photos
- Community Admins may add follow-up photos during verification
- Creates a visual timeline of the issue

### 7.3 AI Processing (Future)

| Use Case             | Description                                     |
| -------------------- | ----------------------------------------------- |
| Content filtering    | Reject inappropriate/irrelevant photos          |
| Quality check        | Reject blurry, dark, or unusable photos         |
| Issue classification | Suggest issue type based on photo content       |
| Duplicate detection  | Identify if photo shows existing reported issue |

**MVP Approach:** Manual review only. AI features in later phases.

---

## 8. Reporting and Analytics

### 8.1 Report Types by Level

**Member Level (Mobile App):**

1. My reported issues and their status
2. Issues near me (map view)
3. Community summary (shared by admins)

**Sector Administrator Level:**

1. Heat report - issues ranked by urgency
2. Status summary - count by state
3. Response time metrics - average time in each state

**Sector Group / Pod Level:**

1. Cross-sector comparison - which sectors have most issues
2. Trend analysis - issues over time
3. Resolution performance - sectors ranked by response time

**Central Authority Level:**

1. Pod health overview
2. System usage statistics
3. Infrastructure cost per pod

### 8.2 Heat Reports

The primary operational report. Shows:

- All open issues ranked by heat score
- Visual heat map overlay on geographic map
- Filtering by issue type, sector, state
- Drill-down to individual issues

---

## 9. Privacy and Data Protection

### 9.1 Personal Data Collected

| Data          | Purpose                    | Visibility                                 |
| ------------- | -------------------------- | ------------------------------------------ |
| Phone number  | Authentication, contact    | Admins only                                |
| Address       | Verify community residency | Sector Admins only                         |
| Name          | Identification             | Admins only                                |
| Issue reports | Core functionality         | Community-wide (without reporter identity) |
| Photos        | Evidence                   | Community-wide                             |

### 9.2 Privacy Principles

- **Minimal collection**: Only collect what's necessary
- **Purpose limitation**: Data used only for stated purposes
- **Access control**: Personal data visible only to relevant administrators
- **Reporter anonymity**: Issue reports visible to community, but reporter identity hidden from other members
- **No public shaming**: Member warnings/flags are private

### 9.3 Data Retention

- **Active issues**: Full data retained
- **Resolved issues**: Retained with minimal data for historical reporting
- **Member data**: Retained while active, deleted on request (with audit trail)

### 9.4 Compliance

- POPIA (South Africa) - primary consideration
- GDPR principles followed as best practice
- Data stored within geographic region where possible

### 9.5 Data Ownership

Data is owned by the community (sector/pod), not by Central Authority. Communities can request data export.

---

## 10. Open Questions for Resolution

The following items need decisions before detailed technical design:

### 10.1 Authentication (RESOLVED)

- [x] **Email + password** for member login (no SMS OTP - too expensive)
- [x] Web-based registration with admin approval workflow
- [x] First-time password change required after admin approval
- [x] PIN/biometric for quick mobile app access after initial login
- [x] JWT tokens with 15-minute access token, 7-day refresh token
- [ ] How to handle device changes? (deferred to Phase 2)
- [ ] Session duration / re-authentication frequency? (deferred to Phase 2)

### 10.2 Notifications

- [ ] How are members notified of status changes? Push notifications? SMS?
- [ ] How do admins receive alerts for new issues?
- [ ] Notification preferences - can users opt out?

### 10.3 Offline Capability

- [ ] Can members create reports while offline (sync later)?
- [ ] How much data is cached on device for offline viewing?

### 10.4 Geographic Boundaries

- [ ] What format for defining sector boundaries?
- [ ] Who creates/maintains boundary definitions?
- [ ] How to handle issues at boundary edges?

### 10.5 Photo Storage

- [ ] Cloud object storage strategy (S3/Azure Blob/GCS)?
- [ ] Image compression/optimization?
- [ ] Retention period for photos of resolved issues?

### 10.6 Multi-language Support

- [ ] Which languages for MVP?
- [ ] Who provides translations?
- [ ] How to handle user-generated content (issue descriptions)?

---

## 11. Document History

| Version | Date     | Author | Changes                                |
| ------- | -------- | ------ | -------------------------------------- |
| 0.1     | Dec 2025 | -      | Initial brain dump                     |
| 0.2     | Dec 2025 | -      | Cleaned up, organized, gaps identified |
| 0.3     | Jan 2026 | -      | Added web registration flow, member status states, authentication decisions |

---

## Next Steps

1. **Resolve open questions** (Section 10) - particularly authentication and notifications
2. **Technology stack selection** - choose languages, frameworks, databases
3. **Entity-relationship model** - detailed database schema
4. **User stories** - MVP feature set with acceptance criteria
