import { type FC } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import CancelIcon from '@mui/icons-material/Cancel';
import PersonAddIcon from '@mui/icons-material/PersonAdd';
import RateReviewIcon from '@mui/icons-material/RateReview';
import SettingsIcon from '@mui/icons-material/Settings';
import PersonRemoveIcon from '@mui/icons-material/PersonRemove';

import { ActionIconButton } from '@/components/atoms/ActionIconButton';
import type { MemberListItem } from '../types';

interface MemberActionsCellProps {
  member: MemberListItem;
  onApprove: (member: MemberListItem) => void;
  onReject: (member: MemberListItem) => void;
  onInvite: (member: MemberListItem) => void;
  onReviewApplication: (member: MemberListItem) => void;
  onManage: (member: MemberListItem) => void;
  onRevokeInvite: (member: MemberListItem) => void;
}

/**
 * Unified actions cell for the Members table.
 * Shows contextual action buttons based on member state.
 */
export const MemberActionsCell: FC<MemberActionsCellProps> = ({
  member,
  onApprove,
  onReject,
  onInvite,
  onReviewApplication,
  onManage,
  onRevokeInvite,
}) => {
  const { t } = useTranslation();

  const stopPropagation = (e: React.MouseEvent) => e.stopPropagation();

  // Priority 1: Pending member approval
  if (member.status === 'pending_approval') {
    return (
      <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'center' }}>
        <ActionIconButton
          color="primary"
          tooltip={t('members.approve')}
          aria-label={t('members.approve')}
          onClick={(e) => {
            stopPropagation(e);
            onApprove(member);
          }}
        >
          <CheckCircleIcon fontSize="small" />
        </ActionIconButton>
        <ActionIconButton
          color="secondary"
          tooltip={t('members.reject')}
          aria-label={t('members.reject')}
          onClick={(e) => {
            stopPropagation(e);
            onReject(member);
          }}
        >
          <CancelIcon fontSize="small" />
        </ActionIconButton>
      </Box>
    );
  }

  // Priority 2: Active Ground Admin - show manage
  if (member.isGroundAdmin) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center' }}>
        <ActionIconButton
          color="primary"
          tooltip={t('groundAdmin.manage')}
          aria-label={t('groundAdmin.manage')}
          onClick={(e) => {
            stopPropagation(e);
            onManage(member);
          }}
        >
          <SettingsIcon fontSize="small" />
        </ActionIconButton>
      </Box>
    );
  }

  // Priority 3: Pending invitation - show revoke
  if (member.hasInvitationPending) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center' }}>
        <ActionIconButton
          color="secondary"
          tooltip={t('members.revokeInvite')}
          aria-label={t('members.revokeInvite')}
          onClick={(e) => {
            stopPropagation(e);
            onRevokeInvite(member);
          }}
        >
          <PersonRemoveIcon fontSize="small" />
        </ActionIconButton>
      </Box>
    );
  }

  // Priority 4: Pending application - show review
  if (member.hasPendingApplication) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center' }}>
        <ActionIconButton
          color="primary"
          tooltip={t('groundAdmin.review')}
          aria-label={t('groundAdmin.review')}
          onClick={(e) => {
            stopPropagation(e);
            onReviewApplication(member);
          }}
        >
          <RateReviewIcon fontSize="small" />
        </ActionIconButton>
      </Box>
    );
  }

  // Priority 5: Active member with issues - show invite
  if (member.status === 'active' && member.issueCount > 0) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center' }}>
        <ActionIconButton
          color="primary"
          tooltip={t('groundAdmin.invite')}
          aria-label={t('groundAdmin.invite')}
          onClick={(e) => {
            stopPropagation(e);
            onInvite(member);
          }}
        >
          <PersonAddIcon fontSize="small" />
        </ActionIconButton>
      </Box>
    );
  }

  // No actions available
  return null;
};
