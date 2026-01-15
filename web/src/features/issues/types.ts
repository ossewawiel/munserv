import type { GeoPoint } from '@/shared/types/common';

export type IssueType =
  | 'pothole'
  | 'water_leak'
  | 'sewage_leak'
  | 'traffic_light'
  | 'street_light'
  | 'illegal_dumping'
  | 'other';

export type IssueState =
  | 'reported'
  | 'confirmed'
  | 'in_progress'
  | 'fixed'
  | 'rejected';

export interface Issue {
  id: string;
  type: IssueType;
  state: IssueState;
  location: GeoPoint;
  address: string | null;
  description: string | null;
  heat: number;
  photoUrls: string[];
  sectorId: string;
  reporterId: string;
  reportCount: number;
  createdAt: string;
  updatedAt: string;
  stateHistory?: StateHistoryEntry[];
}

export interface IssueSummary {
  id: string;
  type: IssueType;
  state: IssueState;
  location: GeoPoint;
  heat: number;
  thumbnailUrl: string;
  createdAt: string;
}

export interface StateHistoryEntry {
  state: IssueState;
  changedAt: string;
  changedBy: string | null;
  note?: string;
}

export const ISSUE_TYPE_LABELS: Record<IssueType, string> = {
  pothole: 'Pothole',
  water_leak: 'Water Leak',
  sewage_leak: 'Sewage Leak',
  traffic_light: 'Traffic Light',
  street_light: 'Street Light',
  illegal_dumping: 'Illegal Dumping',
  other: 'Other',
};

export const ISSUE_STATE_LABELS: Record<IssueState, string> = {
  reported: 'Reported',
  confirmed: 'Confirmed',
  in_progress: 'In Progress',
  fixed: 'Fixed',
  rejected: 'Rejected',
};

/**
 * Request to update issue state
 */
export interface UpdateIssueStateRequest {
  state: IssueState;
  note?: string;
}

/**
 * Issue filter parameters
 */
export interface IssueFilterParams {
  state?: IssueState;
  type?: IssueType;
  sectorId?: string;
  page?: number;
  limit?: number;
}
