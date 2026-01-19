/**
 * Verification mode determines how Ground Admins are notified
 */
export type VerificationMode =
  | 'all_notified'
  | 'admin_assigns'
  | 'nearest_auto'
  | 'first_come';

/**
 * Sector settings for Ground Admin verification workflow
 */
export interface SectorSettings {
  id: string;
  sectorId: string;
  newIssueVerificationMode: VerificationMode;
  fixVerificationMode: VerificationMode;
  daysFixedBeforeClosed: number;
  minimumGroundAdmins: number;
  createdAt: string;
  updatedAt: string;
}

/**
 * Request to update sector settings (partial update)
 */
export interface SectorSettingsUpdate {
  newIssueVerificationMode?: VerificationMode;
  fixVerificationMode?: VerificationMode;
  daysFixedBeforeClosed?: number;
  minimumGroundAdmins?: number;
}

/**
 * Map verification modes to their i18n label keys
 */
export const VERIFICATION_MODE_LABELS: Record<VerificationMode, string> = {
  all_notified: 'sectorSettings.modeOptions.allNotified',
  admin_assigns: 'sectorSettings.modeOptions.adminAssigns',
  nearest_auto: 'sectorSettings.modeOptions.nearestAuto',
  first_come: 'sectorSettings.modeOptions.firstCome',
};

/**
 * Verification modes as array for dropdowns
 */
export const VERIFICATION_MODES: VerificationMode[] = [
  'all_notified',
  'admin_assigns',
  'nearest_auto',
  'first_come',
];
