import { type FC, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { clsx } from 'clsx';

import { Button } from '@/components/atoms/Button';

interface PaginationProps {
  currentPage: number;
  totalPages: number;
  totalItems: number;
  pageSize: number;
  onPageChange: (page: number) => void;
  className?: string;
}

export const Pagination: FC<PaginationProps> = ({
  currentPage,
  totalPages,
  totalItems,
  pageSize,
  onPageChange,
  className,
}) => {
  const { t } = useTranslation();

  const startItem = (currentPage - 1) * pageSize + 1;
  const endItem = Math.min(currentPage * pageSize, totalItems);

  const handlePrevious = useCallback(() => {
    if (currentPage > 1) {
      onPageChange(currentPage - 1);
    }
  }, [currentPage, onPageChange]);

  const handleNext = useCallback(() => {
    if (currentPage < totalPages) {
      onPageChange(currentPage + 1);
    }
  }, [currentPage, totalPages, onPageChange]);

  if (totalPages <= 1) return null;

  return (
    <div
      className={clsx(
        'flex flex-col items-center justify-between gap-4 sm:flex-row',
        className
      )}
    >
      <p className="text-sm text-text-muted">
        {t('pagination.showing')} <span className="font-medium">{startItem}</span>{' '}
        {t('pagination.to')} <span className="font-medium">{endItem}</span>{' '}
        {t('pagination.of')} <span className="font-medium">{totalItems}</span>{' '}
        {t('pagination.results')}
      </p>
      <div className="flex items-center gap-2">
        <Button
          variant="secondary"
          size="sm"
          onClick={handlePrevious}
          disabled={currentPage === 1}
        >
          {t('common.previous')}
        </Button>
        <span className="px-3 text-sm text-text-muted">
          {t('pagination.page')} {currentPage} {t('pagination.of')} {totalPages}
        </span>
        <Button
          variant="secondary"
          size="sm"
          onClick={handleNext}
          disabled={currentPage === totalPages}
        >
          {t('common.next')}
        </Button>
      </div>
    </div>
  );
};
