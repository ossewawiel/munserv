import { type FC, type ReactNode, forwardRef } from 'react';
import Card, { type CardProps } from '@mui/material/Card';
import CardContent from '@mui/material/CardContent';
import CardHeader from '@mui/material/CardHeader';
import Divider from '@mui/material/Divider';
import Typography from '@mui/material/Typography';
import { cardHoverShadow } from '@/theme';

interface MainCardProps extends Omit<CardProps, 'title'> {
  /** Card title */
  title?: ReactNode;
  /** Secondary action (top right) */
  secondary?: ReactNode;
  /** Card content */
  children: ReactNode;
  /** Show divider below header */
  divider?: boolean;
  /** Custom content sx */
  contentSx?: CardProps['sx'];
  /** Enable hover shadow effect */
  hoverEffect?: boolean;
}

export const MainCard: FC<MainCardProps> = forwardRef<HTMLDivElement, MainCardProps>(
  (
    {
      title,
      secondary,
      children,
      divider = true,
      contentSx,
      hoverEffect = true,
      sx,
      ...rest
    },
    ref
  ) => {
    return (
      <Card
        ref={ref}
        variant="outlined"
        sx={{
          // Use CSS variable for dynamic color scheme switching
          bgcolor: 'var(--munserv-palette-background-paper)',
          border: '1px solid',
          borderColor: 'divider',
          ...(hoverEffect && {
            ':hover': {
              boxShadow: cardHoverShadow,
            },
          }),
          ...sx,
        }}
        {...rest}
      >
        {title && (
          <>
            <CardHeader
              sx={{ p: 2.5 }}
              title={
                typeof title === 'string' ? (
                  <Typography variant="h6" sx={{
                    fontWeight: 600
                  }}>
                    {title}
                  </Typography>
                ) : (
                  title
                )
              }
              action={secondary}
            />
            {divider && <Divider />}
          </>
        )}
        <CardContent sx={{ p: 2.5, '&:last-child': { pb: 2.5 }, ...contentSx }}>
          {children}
        </CardContent>
      </Card>
    );
  }
);

MainCard.displayName = 'MainCard';
