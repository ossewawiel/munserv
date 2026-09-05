import { type FC, type ReactNode } from 'react';
import Card from '@mui/material/Card';
import CardContent from '@mui/material/CardContent';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Avatar from '@mui/material/Avatar';
import { useTheme, alpha } from '@mui/material/styles';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';
import TrendingDownIcon from '@mui/icons-material/TrendingDown';
import { cardHoverShadow, avatarSizes, lightScheme } from '@/theme';

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

// Fixed background colors for colored cards - same in light and dark mode
// Uses light scheme values to ensure consistency across themes
const variantBgColors: Record<StatCardVariant, string> = {
  primary: lightScheme.primary,           // #0C2721 - Forest green
  secondary: lightScheme.secondary,       // #A2391A - Terracotta
  success: '#4CAF50',                     // Green
  warning: '#E65100',                     // Dark orange
  error: '#D32F2F',                       // Red
  info: '#1976D2',                        // Blue
};

// Light background colors for icon avatars (when card is not colored)
const variantLightBgColors: Record<StatCardVariant, string> = {
  primary: lightScheme.primaryLight,      // #E8F0ED - Light forest green
  secondary: lightScheme.secondaryLight,  // #FFEAE4 - Light terracotta
  success: '#E8F5E9',                     // Light green
  warning: '#FFF3E0',                     // Light orange
  error: '#FFEBEE',                       // Light red
  info: '#E3F2FD',                        // Light blue
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
        // Use CSS variable for dynamic color scheme switching
        bgcolor: isColored ? variantBgColors[variant] : 'var(--munserv-palette-background-paper)',
        ':hover': {
          boxShadow: cardHoverShadow,
        },
      }}
    >
      <CardContent sx={{ p: 2.5, '&:last-child': { pb: 2.5 } }}>
        <Box sx={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
          <Box>
            <Typography variant="body2" color={secondaryTextColor} sx={{
              fontWeight: 500
            }}>
              {title}
            </Typography>
            <Typography
              variant="h4"
              component="p"
              color={textColor}
              sx={{
                fontWeight: 700,
                mt: 1
              }}>
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
                  color: (() => {
                    if (isColored) return 'common.white';
                    return trend.isPositive ? 'success.main' : 'error.main';
                  })(),
                }}
              >
                {trend.isPositive ? (
                  <TrendingUpIcon sx={{ fontSize: 16, mr: 0.5 }} />
                ) : (
                  <TrendingDownIcon sx={{ fontSize: 16, mr: 0.5 }} />
                )}
                <Typography variant="body2" sx={{
                  fontWeight: 500
                }}>
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
                // Use fixed colors for consistency across light/dark modes
                bgcolor: isColored ? 'rgba(255,255,255,0.2)' : variantLightBgColors[variant],
                color: isColored ? 'common.white' : variantBgColors[variant],
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
