import { type FC } from 'react';
import { useTranslation } from 'react-i18next';
import { clsx } from 'clsx';

import { Button } from '@/components/atoms/Button';

interface ErrorStateProps {
  title?: string;
  description?: string;
  onRetry?: () => void;
  className?: string;
}

export const ErrorState: FC<ErrorStateProps> = ({
  title,
  description,
  onRetry,
  className,
}) => {
  const { t } = useTranslation();

  return (
    <div
      className={clsx(
        'flex flex-col items-center justify-center py-12 text-center',
        className
      )}
    >
      <svg
        className="mb-4 h-12 w-12 text-danger-500"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={1.5}
          d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
        />
      </svg>
      <h3 className="text-lg font-medium text-text">
        {title || t('common.error')}
      </h3>
      {description && (
        <p className="mt-2 max-w-sm text-sm text-text-muted">{description}</p>
      )}
      {onRetry && (
        <Button variant="secondary" onClick={onRetry} className="mt-6">
          {t('common.retry')}
        </Button>
      )}
    </div>
  );
};
