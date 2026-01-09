import { type FC, type ReactNode } from 'react';
import MuiButton, { type ButtonProps as MuiButtonProps } from '@mui/material/Button';

type ActionButtonColor = 'primary' | 'secondary';
type ActionButtonVariant = 'filled' | 'outlined';

interface ActionButtonProps extends Omit<MuiButtonProps, 'variant' | 'color'> {
  /** Color scheme: primary (forest green) or secondary (terracotta) */
  color?: ActionButtonColor;
  /** Variant: filled (Berry avatar style) or outlined */
  variant?: ActionButtonVariant;
  /** Icon to display before text */
  icon?: ReactNode;
  /** Button text */
  children: ReactNode;
}

/**
 * Berry-style action button with soft background colors.
 * Matches the hamburger button styling in the app header.
 *
 * @example
 * // Primary filled (default)
 * <ActionButton icon={<FilterAltOffIcon />}>Clear</ActionButton>
 *
 * // Secondary filled
 * <ActionButton color="secondary" icon={<AddIcon />}>Add</ActionButton>
 *
 * // Primary outlined
 * <ActionButton variant="outlined" icon={<PrintIcon />}>Print</ActionButton>
 */
export const ActionButton: FC<ActionButtonProps> = ({
  color = 'primary',
  variant = 'filled',
  icon,
  children,
  sx,
  ...props
}) => {
  const colorStyles = {
    primary: {
      filled: {
        bgcolor: 'var(--munserv-palette-primary-light)',
        color: 'var(--munserv-palette-primary-dark)',
        '&:hover': {
          bgcolor: 'var(--munserv-palette-primary-main)',
          color: 'var(--munserv-palette-primary-contrastText)',
        },
      },
      outlined: {
        bgcolor: 'transparent',
        color: 'var(--munserv-palette-primary-main)',
        border: '1px solid',
        borderColor: 'var(--munserv-palette-primary-main)',
        '&:hover': {
          bgcolor: 'var(--munserv-palette-primary-light)',
          borderColor: 'var(--munserv-palette-primary-dark)',
        },
      },
    },
    secondary: {
      filled: {
        bgcolor: 'var(--munserv-palette-secondary-light)',
        color: 'var(--munserv-palette-secondary-dark)',
        '&:hover': {
          bgcolor: 'var(--munserv-palette-secondary-main)',
          color: 'var(--munserv-palette-secondary-contrastText)',
        },
      },
      outlined: {
        bgcolor: 'transparent',
        color: 'var(--munserv-palette-secondary-main)',
        border: '1px solid',
        borderColor: 'var(--munserv-palette-secondary-main)',
        '&:hover': {
          bgcolor: 'var(--munserv-palette-secondary-light)',
          borderColor: 'var(--munserv-palette-secondary-dark)',
        },
      },
    },
  };

  return (
    <MuiButton
      startIcon={icon}
      sx={{
        borderRadius: '8px',
        textTransform: 'none',
        fontWeight: 500,
        px: 1.5,
        py: 0.75,
        minWidth: 'auto',
        transition: 'all 0.2s ease-in-out',
        ...colorStyles[color][variant],
        ...sx,
      }}
      {...props}
    >
      {children}
    </MuiButton>
  );
};
