import { type FC } from 'react';
import Skeleton from '@mui/material/Skeleton';
import Box from '@mui/material/Box';
import Stack from '@mui/material/Stack';
import Card from '@mui/material/Card';
import CardContent from '@mui/material/CardContent';
import Grid from '@mui/material/Grid';

interface LoadingSkeletonProps {
  variant?: 'text' | 'rect' | 'circle';
  width?: string | number;
  height?: string | number;
  count?: number;
}

const variantMap = {
  text: 'text' as const,
  rect: 'rectangular' as const,
  circle: 'circular' as const,
};

export const LoadingSkeleton: FC<LoadingSkeletonProps> = ({
  variant = 'rect',
  width,
  height,
  count = 1,
}) => {
  if (count === 1) {
    return (
      <Skeleton
        variant={variantMap[variant]}
        width={width}
        height={height}
        animation="wave"
      />
    );
  }

  return (
    <Stack spacing={1.5}>
      {Array.from({ length: count }).map((_, index) => (
        <Skeleton
          key={index}
          variant={variantMap[variant]}
          width={width}
          height={height}
          animation="wave"
        />
      ))}
    </Stack>
  );
};

interface TableSkeletonProps {
  rows?: number;
  columns?: number;
}

export const TableSkeleton: FC<TableSkeletonProps> = ({
  rows = 5,
  columns = 4,
}) => {
  return (
    <Box sx={{ width: '100%' }}>
      <Box sx={{ display: 'flex', gap: 2, mb: 2 }}>
        {Array.from({ length: columns }).map((_, i) => (
          <Skeleton key={i} variant="text" sx={{ flex: 1, height: 24 }} animation="wave" />
        ))}
      </Box>
      {Array.from({ length: rows }).map((_, rowIndex) => (
        <Box key={rowIndex} sx={{ display: 'flex', gap: 2, mb: 1.5 }}>
          {Array.from({ length: columns }).map((_, colIndex) => (
            <Skeleton
              key={colIndex}
              variant="rectangular"
              sx={{ flex: 1, height: 40, borderRadius: 1 }}
              animation="wave"
            />
          ))}
        </Box>
      ))}
    </Box>
  );
};

interface CardSkeletonProps {
  count?: number;
}

export const CardSkeleton: FC<CardSkeletonProps> = ({ count = 4 }) => {
  return (
    <Grid container spacing={2}>
      {Array.from({ length: count }).map((_, index) => (
        <Grid size={{ xs: 12, sm: 6, lg: 3 }} key={index}>
          <Card variant="outlined">
            <CardContent>
              <Skeleton variant="text" width={100} height={20} sx={{ mb: 1 }} animation="wave" />
              <Skeleton variant="text" width={80} height={32} animation="wave" />
            </CardContent>
          </Card>
        </Grid>
      ))}
    </Grid>
  );
};
