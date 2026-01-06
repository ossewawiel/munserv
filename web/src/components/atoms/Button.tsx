import { type FC } from 'react';
import MuiButton, { type ButtonProps as MuiButtonProps } from '@mui/material/Button';
import CircularProgress from '@mui/material/CircularProgress';

type ButtonVariant = 'primary' | 'secondary' | 'danger' | 'ghost';

interface ButtonProps extends Omit<MuiButtonProps, 'variant' | 'color'> {
  variant?: ButtonVariant;
  isLoading?: boolean;
}

const variantMap: Record<ButtonVariant, { variant: MuiButtonProps['variant']; color: MuiButtonProps['color'] }> = {
  primary: { variant: 'contained', color: 'primary' },
  secondary: { variant: 'outlined', color: 'inherit' },
  danger: { variant: 'contained', color: 'error' },
  ghost: { variant: 'text', color: 'inherit' },
};

export const Button: FC<ButtonProps> = ({
  variant = 'primary',
  isLoading = false,
  children,
  disabled,
  size = 'medium',
  ...props
}) => {
  const { variant: muiVariant, color } = variantMap[variant];

  return (
    <MuiButton
      variant={muiVariant}
      color={color}
      size={size}
      disabled={disabled || isLoading}
      startIcon={isLoading ? <CircularProgress size={16} color="inherit" /> : undefined}
      {...props}
    >
      {isLoading ? 'Loading...' : children}
    </MuiButton>
  );
};
