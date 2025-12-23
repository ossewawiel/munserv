import type { IssueState, IssueType } from '../issues/types';

export interface DashboardStats {
  sectorId: string;
  sectorName: string;
  stats: {
    totalOpen: number;
    byState: Record<IssueState, number>;
    byType: Partial<Record<IssueType, number>>;
    avgResolutionDays: number;
    reportedThisWeek: number;
  };
}

export interface HeatReportItem {
  id: string;
  type: IssueType;
  state: IssueState;
  heat: number;
  daysOpen: number;
  reportCount: number;
  location: {
    latitude: number;
    longitude: number;
  };
  thumbnailUrl: string;
}

export interface HeatReport {
  generatedAt: string;
  items: HeatReportItem[];
}
