import { type FC } from 'react';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';
import LightModeIcon from '@mui/icons-material/LightMode';
import DarkModeIcon from '@mui/icons-material/DarkMode';
import SettingsBrightnessIcon from '@mui/icons-material/SettingsBrightness';
import { useThemeContext } from '@/theme';
import type { ColorMode } from '@/theme/types';

interface ThemeToggleProps {
  size?: 'small' | 'medium' | 'large';
}

const modeIcons: Record<ColorMode, typeof LightModeIcon> = {
  light: LightModeIcon,
  dark: DarkModeIcon,
  system: SettingsBrightnessIcon,
};

const modeLabels: Record<ColorMode, string> = {
  light: 'Light mode',
  dark: 'Dark mode',
  system: 'System preference',
};

const nextMode: Record<ColorMode, ColorMode> = {
  light: 'dark',
  dark: 'system',
  system: 'light',
};

export const ThemeToggle: FC<ThemeToggleProps> = ({ size = 'medium' }) => {
  const { colorMode, setColorMode } = useThemeContext();

  const handleToggle = () => {
    setColorMode(nextMode[colorMode]);
  };

  const Icon = modeIcons[colorMode];
  const label = modeLabels[colorMode];

  return (
    <Tooltip title={`${label} - Click to change`}>
      <IconButton
        onClick={handleToggle}
        size={size}
        sx={{
          color: 'text.secondary',
          '&:hover': {
            color: 'primary.main',
          },
        }}
        aria-label={`Current: ${label}. Click to toggle theme.`}
      >
        <Icon fontSize={size} />
      </IconButton>
    </Tooltip>
  );
};
