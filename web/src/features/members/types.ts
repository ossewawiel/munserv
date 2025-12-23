/**
 * Member summary for list views
 */
export interface MemberListItem {
  id: string;
  displayName: string;
  phoneNumber: string;
  issueCount: number;
  joinedAt: string;
}

/**
 * Full member entity
 */
export interface Member {
  id: string;
  phoneNumber: string;
  displayName: string;
  sectorId: string;
  issueCount: number;
  createdAt: string;
  updatedAt: string;
}

/**
 * Member filter parameters
 */
export interface MemberFilterParams {
  sectorId?: string;
  search?: string;
  page?: number;
  limit?: number;
}
