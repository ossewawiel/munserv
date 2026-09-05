import { type FC } from 'react';
import { Link as RouterLink } from 'react-router-dom';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import MuiBreadcrumbs from '@mui/material/Breadcrumbs';
import Link from '@mui/material/Link';
import NavigateNextIcon from '@mui/icons-material/NavigateNext';
import HomeIcon from '@mui/icons-material/Home';

export interface BreadcrumbItem {
  /** Display label for the breadcrumb item */
  label: string;
  /** Path to navigate to. If not provided, item is rendered as text (current page) */
  path?: string;
  /** If true, renders a home icon instead of label (for root/dashboard link) */
  icon?: 'home';
}

interface BreadcrumbsProps {
  /** Page title displayed on the left */
  title: string;
  /** Optional subtitle displayed below the title */
  subtitle?: string;
  /** Breadcrumb trail items. Last item without path is considered current page */
  items: BreadcrumbItem[];
}

export const Breadcrumbs: FC<BreadcrumbsProps> = ({ title, subtitle, items }) => {
  return (
    <Box
      sx={{
        display: 'flex',
        flexDirection: { xs: 'column', sm: 'row' },
        alignItems: { xs: 'flex-start', sm: 'center' },
        justifyContent: 'space-between',
        gap: 2,
        p: 2,
        bgcolor: 'background.paper',
        borderRadius: 1,
        border: 1,
        borderColor: 'divider',
      }}
    >
      {/* Left side: Title and optional subtitle */}
      <Box>
        <Typography variant="h5" component="h1" color="primary" sx={{
          fontWeight: 600
        }}>
          {title}
        </Typography>
        {subtitle && (
          <Typography
            variant="body2"
            sx={{
              color: "text.secondary",
              mt: 0.5
            }}>
            {subtitle}
          </Typography>
        )}
      </Box>

      {/* Right side: Breadcrumb trail */}
      <MuiBreadcrumbs
        aria-label="breadcrumb"
        separator={<NavigateNextIcon fontSize="small" />}
        sx={{
          '& .MuiBreadcrumbs-separator': {
            mx: 1,
          },
        }}
      >
        {items.map((item, index) => {
          const isLast = index === items.length - 1;
          const isCurrent = !item.path;

          if (isCurrent || isLast) {
            return (
              <Typography
                key={item.label}
                variant="subtitle2"
                aria-current={isLast ? 'page' : undefined}
                sx={{
                  color: "text.secondary"
                }}
              >
                {item.label}
              </Typography>
            );
          }

          return (
            <Link
              key={item.label}
              component={RouterLink}
              to={item.path!}
              underline="hover"
              color="inherit"
              variant="subtitle2"
              aria-label={item.icon === 'home' ? item.label : undefined}
              sx={{
                display: 'flex',
                alignItems: 'center',
                '&:hover': {
                  color: 'primary.main',
                },
              }}
            >
              {item.icon === 'home' ? (
                <HomeIcon fontSize="small" />
              ) : (
                item.label
              )}
            </Link>
          );
        })}
      </MuiBreadcrumbs>
    </Box>
  );
};
