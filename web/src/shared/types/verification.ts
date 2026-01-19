/**
 * Reason for why verification cannot be completed
 */
export type VerificationReason =
  | 'busy'
  | 'away'
  | 'cannot_find'
  | 'wrong_location'
  | 'not_an_issue';

/**
 * Type of verification being performed
 */
export type VerificationType = 'existence' | 'fix';

/**
 * Result of a verification
 */
export type VerificationResult =
  | 'confirmed'
  | 'not_found'
  | 'not_fixed'
  | 'cannot_verify';

/**
 * Status of a verification request
 */
export type VerificationStatus = 'pending' | 'completed' | 'expired';

/**
 * Issue verification record
 */
export interface IssueVerification {
  id: string;
  issueId: string;
  verificationType: VerificationType;
  assignedTo?: string;
  assignedToName?: string;
  verifiedBy?: string;
  verifiedByName?: string;
  result?: VerificationResult;
  reason?: VerificationReason;
  note?: string;
  photoId?: string;
  requestedAt: string;
  respondedAt?: string;
  status: VerificationStatus;
}

/**
 * Request to create a verification request for an issue
 */
export interface RequestVerificationRequest {
  type: VerificationType;
  assignTo?: string;
  message?: string;
}

/**
 * Response from verification history endpoint
 */
export interface VerificationHistoryResponse {
  items: IssueVerification[];
}

/**
 * Map verification reasons to i18n label keys
 */
export const VERIFICATION_REASON_LABELS: Record<VerificationReason, string> = {
  busy: 'verification.reasons.busy',
  away: 'verification.reasons.away',
  cannot_find: 'verification.reasons.cannotFind',
  wrong_location: 'verification.reasons.wrongLocation',
  not_an_issue: 'verification.reasons.notAnIssue',
};

/**
 * Map verification results to i18n label keys
 */
export const VERIFICATION_RESULT_LABELS: Record<VerificationResult, string> = {
  confirmed: 'verification.results.confirmed',
  not_found: 'verification.results.notFound',
  not_fixed: 'verification.results.notFixed',
  cannot_verify: 'verification.results.cannotVerify',
};

/**
 * Verification reasons as array for dropdowns
 */
export const VERIFICATION_REASONS: VerificationReason[] = [
  'busy',
  'away',
  'cannot_find',
  'wrong_location',
  'not_an_issue',
];
