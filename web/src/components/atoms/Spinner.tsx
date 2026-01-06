import { type FC } from 'react';
import CircularProgress, { type CircularProgressProps } from '@mui/material/CircularProgress';

const sizeMap = {
  sm: 16,
  md: 24,
  lg: 32,
};

interface SpinnerProps {
  size?: keyof typeof sizeMap;
  color?: CircularProgressProps['color'];
}

export const Spinner: FC<SpinnerProps> = ({ size = 'md', color = 'primary' }) => {
  return <CircularProgress size={sizeMap[size]} color={color} />;
};
