import { type FC, type ReactNode } from 'react';
import { clsx } from 'clsx';

const variantStyles = {
  default: 'bg-secondary-100 text-secondary-800',
  primary: 'bg-primary-100 text-primary-800',
  success: 'bg-success-100 text-success-700',
  warning: 'bg-warning-100 text-warning-700',
  danger: 'bg-danger-100 text-danger-700',
  info: 'bg-info-100 text-info-700',
};

interface BadgeProps {
  children: ReactNode;
  variant?: keyof typeof variantStyles;
  className?: string;
}

export const Badge: FC<BadgeProps> = ({
  children,
  variant = 'default',
  className,
}) => {
  return (
    <span
      className={clsx(
        'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium',
        variantStyles[variant],
        className
      )}
    >
      {children}
    </span>
  );
};
