import { type FC, type ReactNode } from 'react';
import Card from '@mui/material/Card';
import CardContent from '@mui/material/CardContent';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Avatar from '@mui/material/Avatar';
import { useTheme, alpha } from '@mui/material/styles';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';
import TrendingDownIcon from '@mui/icons-material/TrendingDown';
import { cardHoverShadow, avatarSizes } from '@/theme';

type StatCardVariant = 'primary' | 'secondary' | 'success' | 'warning' | 'error' | 'info';

interface StatCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  icon?: ReactNode;
  variant?: StatCardVariant;
  /** Use colored background instead of white card */
  colored?: boolean;
  trend?: {
    value: number;
    isPositive: boolean;
  };
}

// Background colors for colored cards (darker shades for good contrast)
const variantBgColors: Record<StatCardVariant, string> = {
  primary: 'primary.dark',
  secondary: 'secondary.main',
  success: 'success.main',
  warning: 'warning.dark',
  error: 'error.main',
  info: 'info.main',
};

export const StatCard: FC<StatCardProps> = ({
  title,
  value,
  subtitle,
  icon,
  variant = 'primary',
  colored = false,
  trend,
}) => {
  const theme = useTheme();
  const isColored = colored;
  const textColor = isColored ? 'common.white' : 'text.primary';
  const secondaryTextColor = isColored
    ? alpha(theme.palette.common.white, 0.7)
    : 'text.secondary';

  return (
    <Card
      variant={isColored ? 'elevation' : 'outlined'}
      sx={{
        border: isColored ? 'none' : '1px solid',
        borderColor: isColored ? 'transparent' : 'divider',
        bgcolor: isColored ? variantBgColors[variant] : 'background.paper',
        ':hover': {
          boxShadow: cardHoverShadow,
        },
      }}
    >
      <CardContent sx={{ p: 2.5, '&:last-child': { pb: 2.5 } }}>
        <Box sx={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
          <Box>
            <Typography variant="body2" color={secondaryTextColor} fontWeight={500}>
              {title}
            </Typography>
            <Typography variant="h4" component="p" fontWeight={700} color={textColor} sx={{ mt: 1 }}>
              {value}
            </Typography>
            {subtitle && (
              <Typography variant="body2" color={secondaryTextColor} sx={{ mt: 0.5 }}>
                {subtitle}
              </Typography>
            )}
            {trend && (
              <Box
                sx={{
                  display: 'flex',
                  alignItems: 'center',
                  mt: 1,
                  color: isColored
                    ? 'common.white'
                    : trend.isPositive
                      ? 'success.main'
                      : 'error.main',
                }}
              >
                {trend.isPositive ? (
                  <TrendingUpIcon sx={{ fontSize: 16, mr: 0.5 }} />
                ) : (
                  <TrendingDownIcon sx={{ fontSize: 16, mr: 0.5 }} />
                )}
                <Typography variant="body2" fontWeight={500}>
                  {Math.abs(trend.value)}%
                </Typography>
              </Box>
            )}
          </Box>
          {icon && (
            <Avatar
              sx={{
                width: avatarSizes.large.width,
                height: avatarSizes.large.height,
                bgcolor: isColored ? 'rgba(255,255,255,0.2)' : `${variant}.light`,
                color: isColored ? 'common.white' : `${variant}.dark`,
                '& .MuiSvgIcon-root': {
                  fontSize: avatarSizes.large.fontSize,
                },
              }}
            >
              {icon}
            </Avatar>
          )}
        </Box>
      </CardContent>
    </Card>
  );
};
