# Backlog

## Explicitly Deferred from MVP

| Feature | Why Deferred | Phase |
|---------|--------------|-------|
| Member management (suspend/warn) | Basic approve/reject in MVP, full management later | 2 |
| Sector boundary editing | Complex, use fixed test boundary | 2 |
| Push notifications | Requires backend infrastructure | 2 |
| Duplicate issue linking | Needs AI or complex UX | 2 |
| Reports export (PDF/Excel) | Nice-to-have | 2 |
| Pod/sector hierarchy | Single sector is enough for MVP | 2 |
| Community Admin role | Sector Admin sufficient for MVP | 2 |
| Social login, 2FA | Phone + OTP sufficient | 2 |
| AI photo analysis | Basic categorization first | 3 |
| Offline mode | Requires significant architecture | 3 |
| Multi-language | English only for MVP | 3 |

## Future Stories (Phase 2+)

| ID | Story | Platform | Priority |
|----|-------|----------|----------|
| B1 | Push notifications for issue updates | mobile | Phase 2 |
| B2 | Member profile management | mobile, web | Phase 2 |
| B3 | Issue comments/discussion | mobile, web | Phase 2 |
| B4 | Bulk issue operations | web | Phase 2 |
| B5 | Export reports to PDF | web | Phase 3 |
| B6 | Offline mode for mobile | mobile | Phase 3 |
| B7 | Suspend/warn member | web | Phase 2 |
| B8 | Edit sector boundaries | web | Phase 2 |

## MVP Success Criteria

MVP is complete when:
- [x] Member can report an issue with photo and see it on a map
- [x] Admin can view issues, change states, and see a basic heat list
- [x] Both apps work against the same API
- [ ] M1 (email/password login with PIN setup) complete
- [ ] W8, W9 (member registration flow) complete
