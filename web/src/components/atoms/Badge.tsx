import { type FC, type ReactNode } from 'react';
import Chip, { type ChipProps } from '@mui/material/Chip';

type BadgeVariant = 'default' | 'primary' | 'success' | 'warning' | 'danger' | 'info';

const colorMap: Record<BadgeVariant, ChipProps['color']> = {
  default: 'default',
  primary: 'primary',
  success: 'success',
  warning: 'warning',
  danger: 'error',
  info: 'info',
};

interface BadgeProps {
  children: ReactNode;
  variant?: BadgeVariant;
}

export const Badge: FC<BadgeProps> = ({ children, variant = 'default' }) => {
  return (
    <Chip
      label={children}
      color={colorMap[variant]}
      size="small"
    />
  );
};
