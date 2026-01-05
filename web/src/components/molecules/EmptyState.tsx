import { type FC, type ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import { clsx } from 'clsx';

interface EmptyStateProps {
  title?: string;
  description?: string;
  icon?: ReactNode;
  action?: ReactNode;
  className?: string;
}

export const EmptyState: FC<EmptyStateProps> = ({
  title,
  description,
  icon,
  action,
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
      {icon ? (
        <div className="mb-4 text-text-muted">{icon}</div>
      ) : (
        <svg
          className="mb-4 h-12 w-12 text-text-muted"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={1.5}
            d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"
          />
        </svg>
      )}
      <h3 className="text-lg font-medium text-text">
        {title || t('common.noResults')}
      </h3>
      {description && (
        <p className="mt-2 max-w-sm text-sm text-text-muted">{description}</p>
      )}
      {action && <div className="mt-6">{action}</div>}
    </div>
  );
};
