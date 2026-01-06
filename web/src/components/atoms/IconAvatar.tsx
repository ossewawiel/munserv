import { type FC, type ReactNode } from 'react';
import Avatar from '@mui/material/Avatar';
import { avatarSizes, type AvatarSize } from '@/theme';

type IconAvatarVariant = 'primary' | 'secondary' | 'success' | 'warning' | 'error' | 'info';

interface IconAvatarProps {
  children: ReactNode;
  size?: AvatarSize;
  variant?: IconAvatarVariant;
}

const variantColors: Record<IconAvatarVariant, { bgcolor: string; color: string }> = {
  primary: { bgcolor: 'primary.light', color: 'primary.dark' },
  secondary: { bgcolor: 'secondary.light', color: 'secondary.dark' },
  success: { bgcolor: 'success.light', color: 'success.dark' },
  warning: { bgcolor: 'warning.light', color: 'warning.dark' },
  error: { bgcolor: 'error.light', color: 'error.dark' },
  info: { bgcolor: 'info.light', color: 'info.dark' },
};

export const IconAvatar: FC<IconAvatarProps> = ({
  children,
  size = 'medium',
  variant = 'primary',
}) => {
  const sizeStyles = avatarSizes[size];
  const colorStyles = variantColors[variant];

  return (
    <Avatar
      sx={{
        width: sizeStyles.width,
        height: sizeStyles.height,
        bgcolor: colorStyles.bgcolor,
        color: colorStyles.color,
        '& .MuiSvgIcon-root': {
          fontSize: sizeStyles.fontSize,
        },
      }}
    >
      {children}
    </Avatar>
  );
};
