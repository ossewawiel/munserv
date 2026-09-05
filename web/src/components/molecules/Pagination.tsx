import { type FC, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import MuiPagination from '@mui/material/Pagination';

interface PaginationProps {
  currentPage: number;
  totalPages: number;
  totalItems: number;
  pageSize: number;
  onPageChange: (page: number) => void;
}

export const Pagination: FC<PaginationProps> = ({
  currentPage,
  totalPages,
  totalItems,
  pageSize,
  onPageChange,
}) => {
  const { t } = useTranslation();

  const startItem = (currentPage - 1) * pageSize + 1;
  const endItem = Math.min(currentPage * pageSize, totalItems);

  const handleChange = useCallback(
    (_event: React.ChangeEvent<unknown>, page: number) => {
      onPageChange(page);
    },
    [onPageChange]
  );

  if (totalPages <= 1) return null;

  return (
    <Box
      sx={{
        display: 'flex',
        flexDirection: { xs: 'column', sm: 'row' },
        alignItems: 'center',
        justifyContent: 'space-between',
        gap: 2,
      }}
    >
      <Typography variant="body2" sx={{
        color: "text.secondary"
      }}>
        {t('pagination.showing')} <strong>{startItem}</strong>{' '}
        {t('pagination.to')} <strong>{endItem}</strong>{' '}
        {t('pagination.of')} <strong>{totalItems}</strong>{' '}
        {t('pagination.results')}
      </Typography>
      <MuiPagination
        count={totalPages}
        page={currentPage}
        onChange={handleChange}
        color="primary"
        size="small"
        showFirstButton
        showLastButton
      />
    </Box>
  );
};
