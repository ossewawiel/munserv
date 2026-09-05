import { type FC } from 'react';
import Avatar from '@mui/material/Avatar';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';

import type { MemberListItem } from '../types';

interface MemberNameCellProps {
  member: MemberListItem;
}

export const MemberNameCell: FC<MemberNameCellProps> = ({ member }) => {
  return (
    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
      <Avatar
        sx={{
          width: 40,
          height: 40,
          bgcolor:
            member.status === 'pending_approval'
              ? 'warning.main'
              : 'primary.light',
          color:
            member.status === 'pending_approval'
              ? 'warning.contrastText'
              : 'primary.contrastText',
          fontSize: '0.875rem',
          fontWeight: 600,
        }}
      >
        {member.firstName.charAt(0)}
        {member.surname.charAt(0)}
      </Avatar>
      <Box>
        <Typography variant="body2" sx={{
          fontWeight: 500
        }}>
          {member.firstName} {member.surname}
        </Typography>
        <Typography variant="caption" sx={{
          color: "text.secondary"
        }}>
          {member.email}
        </Typography>
      </Box>
    </Box>
  );
};
