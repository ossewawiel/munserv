import { type FC, type ReactNode } from 'react';
import IconButton, { type IconButtonProps } from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';

type ActionIconButtonColor = 'primary' | 'secondary';

interface ActionIconButtonProps extends Omit<IconButtonProps, 'color'> {
  /** Color scheme: primary (positive actions) or secondary (negative actions) */
  color?: ActionIconButtonColor;
  /** Tooltip text */
  tooltip?: string;
  /** Icon to display */
  children: ReactNode;
}

/**
 * Berry-style action icon button with soft background colors.
 * Used for table action columns and toolbars.
 *
 * - Primary (green): positive actions like approve, invite, manage, review
 * - Secondary (terracotta): negative actions like reject, revoke, remove
 *
 * @example
 * // Primary (default) - for positive actions
 * <ActionIconButton tooltip="Approve" onClick={handleApprove}>
 *   <CheckCircleIcon />
 * </ActionIconButton>
 *
 * // Secondary - for negative actions
 * <ActionIconButton color="secondary" tooltip="Reject" onClick={handleReject}>
 *   <CancelIcon />
 * </ActionIconButton>
 */
export const ActionIconButton: FC<ActionIconButtonProps> = ({
  color = 'primary',
  tooltip,
  children,
  sx,
  ...props
}) => {
  const colorStyles = {
    primary: {
      bgcolor: 'var(--munserv-palette-primary-light)',
      color: 'var(--munserv-palette-primary-dark)',
      '&:hover': {
        bgcolor: 'var(--munserv-palette-primary-main)',
        color: 'var(--munserv-palette-primary-contrastText)',
      },
    },
    secondary: {
      bgcolor: 'var(--munserv-palette-secondary-light)',
      color: 'var(--munserv-palette-secondary-dark)',
      '&:hover': {
        bgcolor: 'var(--munserv-palette-secondary-main)',
        color: 'var(--munserv-palette-secondary-contrastText)',
      },
    },
  };

  const button = (
    <IconButton
      size="small"
      sx={{
        borderRadius: '8px',
        width: 32,
        height: 32,
        transition: 'all 0.2s ease-in-out',
        ...colorStyles[color],
        ...sx,
      }}
      {...props}
    >
      {children}
    </IconButton>
  );

  if (tooltip) {
    return <Tooltip title={tooltip}>{button}</Tooltip>;
  }

  return button;
};
