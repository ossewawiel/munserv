import { type FC } from 'react';
import { clsx } from 'clsx';

interface LoadingSkeletonProps {
  variant?: 'text' | 'rect' | 'circle';
  width?: string | number;
  height?: string | number;
  className?: string;
  count?: number;
}

export const LoadingSkeleton: FC<LoadingSkeletonProps> = ({
  variant = 'rect',
  width,
  height,
  className,
  count = 1,
}) => {
  const baseClasses = 'animate-pulse bg-secondary-200';

  const variantClasses = {
    text: 'h-4 rounded',
    rect: 'rounded-md',
    circle: 'rounded-full',
  };

  const style: React.CSSProperties = {};
  if (width) style.width = typeof width === 'number' ? `${width}px` : width;
  if (height) style.height = typeof height === 'number' ? `${height}px` : height;

  if (count === 1) {
    return (
      <div
        className={clsx(baseClasses, variantClasses[variant], className)}
        style={style}
      />
    );
  }

  return (
    <div className="space-y-3">
      {Array.from({ length: count }).map((_, index) => (
        <div
          key={index}
          className={clsx(baseClasses, variantClasses[variant], className)}
          style={style}
        />
      ))}
    </div>
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
    <div className="w-full">
      <div className="mb-4 flex gap-4">
        {Array.from({ length: columns }).map((_, i) => (
          <LoadingSkeleton key={i} variant="text" className="h-4 flex-1" />
        ))}
      </div>
      {Array.from({ length: rows }).map((_, rowIndex) => (
        <div key={rowIndex} className="mb-3 flex gap-4">
          {Array.from({ length: columns }).map((_, colIndex) => (
            <LoadingSkeleton
              key={colIndex}
              variant="text"
              className="h-8 flex-1"
            />
          ))}
        </div>
      ))}
    </div>
  );
};

interface CardSkeletonProps {
  count?: number;
}

export const CardSkeleton: FC<CardSkeletonProps> = ({ count = 4 }) => {
  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
      {Array.from({ length: count }).map((_, index) => (
        <div
          key={index}
          className="rounded-lg border border-border bg-background p-6"
        >
          <LoadingSkeleton variant="text" className="mb-2 h-4 w-24" />
          <LoadingSkeleton variant="text" className="h-8 w-20" />
        </div>
      ))}
    </div>
  );
};
