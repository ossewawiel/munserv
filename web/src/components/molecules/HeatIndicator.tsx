import { type FC, useMemo } from 'react';
import { clsx } from 'clsx';

interface HeatIndicatorProps {
  heat: number;
  showValue?: boolean;
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

export const HeatIndicator: FC<HeatIndicatorProps> = ({
  heat,
  showValue = true,
  size = 'md',
  className,
}) => {
  const heatLevel = useMemo(() => {
    if (heat >= 80) return 'critical';
    if (heat >= 60) return 'high';
    if (heat >= 40) return 'medium';
    if (heat >= 20) return 'low';
    return 'minimal';
  }, [heat]);

  const heatColors = {
    critical: 'bg-danger-500',
    high: 'bg-warning-500',
    medium: 'bg-accent-500',
    low: 'bg-success-500',
    minimal: 'bg-secondary-300',
  };

  const textColors = {
    critical: 'text-danger-700',
    high: 'text-warning-700',
    medium: 'text-accent-700',
    low: 'text-success-700',
    minimal: 'text-secondary-600',
  };

  const sizeStyles = {
    sm: 'h-1.5',
    md: 'h-2',
    lg: 'h-3',
  };

  const textSizes = {
    sm: 'text-xs',
    md: 'text-sm',
    lg: 'text-base',
  };

  return (
    <div className={clsx('flex items-center gap-2', className)}>
      <div
        className={clsx(
          'flex-1 overflow-hidden rounded-full bg-secondary-200',
          sizeStyles[size]
        )}
      >
        <div
          className={clsx(
            'h-full rounded-full transition-all',
            heatColors[heatLevel]
          )}
          style={{ width: `${Math.min(heat, 100)}%` }}
        />
      </div>
      {showValue && (
        <span
          className={clsx(
            'min-w-[2.5rem] font-semibold',
            textSizes[size],
            textColors[heatLevel]
          )}
        >
          {heat}
        </span>
      )}
    </div>
  );
};

interface HeatBadgeProps {
  heat: number;
  className?: string;
}

export const HeatBadge: FC<HeatBadgeProps> = ({ heat, className }) => {
  const heatLevel = useMemo(() => {
    if (heat >= 80) return 'critical';
    if (heat >= 60) return 'high';
    if (heat >= 40) return 'medium';
    if (heat >= 20) return 'low';
    return 'minimal';
  }, [heat]);

  const styles = {
    critical: 'bg-danger-100 text-danger-700 border-danger-200',
    high: 'bg-warning-100 text-warning-700 border-warning-200',
    medium: 'bg-accent-100 text-accent-700 border-accent-200',
    low: 'bg-success-100 text-success-700 border-success-200',
    minimal: 'bg-secondary-100 text-secondary-700 border-secondary-200',
  };

  return (
    <span
      className={clsx(
        'inline-flex items-center rounded-full border px-2.5 py-0.5 text-sm font-semibold',
        styles[heatLevel],
        className
      )}
    >
      {heat}
    </span>
  );
};
