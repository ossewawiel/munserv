export const REPORT_SCOPES = ['pod', 'ward', 'sector'] as const;
export type ReportScope = (typeof REPORT_SCOPES)[number];

export const REPORT_TABS = ['summary', 'issues', 'performance'] as const;
export type ReportTab = (typeof REPORT_TABS)[number];
