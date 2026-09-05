import type { Meta, StoryObj } from '@storybook/react-vite';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Stack from '@mui/material/Stack';

import {
  schemeLight,
  schemeDark,
  semanticIssueState,
  semanticIssueType,
  semanticHeat,
  semanticStatus,
  semanticText,
  semanticSurface,
  spacing,
  radius,
  iconSize,
  thumbnailSize,
  layout,
} from './tokens';

function ColorSwatches({ colors }: { colors: Record<string, string> }) {
  return (
    <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(160px, 1fr))', gap: 2 }}>
      {Object.entries(colors).map(([name, value]) => (
        <Stack key={name} spacing={0.5}>
          <Box
            sx={{
              height: 56,
              borderRadius: 1,
              border: 1,
              borderColor: 'divider',
              bgcolor: value,
            }}
          />
          <Typography variant="caption" sx={{ fontWeight: 600 }}>
            {name}
          </Typography>
          <Typography variant="caption" sx={{ color: 'text.secondary' }}>
            {value}
          </Typography>
        </Stack>
      ))}
    </Box>
  );
}

function SizeScale({ sizes }: { sizes: Record<string, number> }) {
  return (
    <Stack spacing={1.5}>
      {Object.entries(sizes).map(([name, value]) => (
        <Box key={name} sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <Typography variant="body2" sx={{ width: 140, fontWeight: 600 }}>
            {name}
          </Typography>
          <Box
            sx={{
              width: Math.min(value, 300),
              height: 16,
              bgcolor: 'primary.main',
              borderRadius: 0.5,
            }}
          />
          <Typography variant="caption" sx={{ color: 'text.secondary' }}>
            {value}px
          </Typography>
        </Box>
      ))}
    </Stack>
  );
}

function TokenCatalogue() {
  return (
    <Stack spacing={4} sx={{ p: 2 }}>
      <Box>
        <Typography variant="h6" sx={{ mb: 2 }}>Light scheme</Typography>
        <ColorSwatches colors={schemeLight} />
      </Box>

      <Box>
        <Typography variant="h6" sx={{ mb: 2 }}>Dark scheme</Typography>
        <ColorSwatches colors={schemeDark} />
      </Box>

      <Box>
        <Typography variant="h6" sx={{ mb: 2 }}>Issue state</Typography>
        <ColorSwatches colors={semanticIssueState} />
      </Box>

      <Box>
        <Typography variant="h6" sx={{ mb: 2 }}>Issue type</Typography>
        <ColorSwatches colors={semanticIssueType} />
      </Box>

      <Box>
        <Typography variant="h6" sx={{ mb: 2 }}>Heat</Typography>
        <ColorSwatches colors={semanticHeat} />
      </Box>

      <Box>
        <Typography variant="h6" sx={{ mb: 2 }}>Status</Typography>
        <ColorSwatches colors={semanticStatus} />
      </Box>

      <Box>
        <Typography variant="h6" sx={{ mb: 2 }}>Text</Typography>
        <ColorSwatches colors={semanticText} />
      </Box>

      <Box>
        <Typography variant="h6" sx={{ mb: 2 }}>Surface</Typography>
        <ColorSwatches colors={semanticSurface} />
      </Box>

      <Box>
        <Typography variant="h6" sx={{ mb: 2 }}>Spacing</Typography>
        <SizeScale sizes={spacing} />
      </Box>

      <Box>
        <Typography variant="h6" sx={{ mb: 2 }}>Radius</Typography>
        <SizeScale sizes={radius} />
      </Box>

      <Box>
        <Typography variant="h6" sx={{ mb: 2 }}>Icon size</Typography>
        <SizeScale sizes={iconSize} />
      </Box>

      <Box>
        <Typography variant="h6" sx={{ mb: 2 }}>Thumbnail size</Typography>
        <SizeScale sizes={thumbnailSize} />
      </Box>

      <Box>
        <Typography variant="h6" sx={{ mb: 2 }}>Layout</Typography>
        <SizeScale sizes={{ ...layout }} />
      </Box>
    </Stack>
  );
}

const meta = {
  title: 'Design/Tokens',
  component: TokenCatalogue,
} satisfies Meta<typeof TokenCatalogue>;

export default meta;
type Story = StoryObj<typeof meta>;

export const AllTokens: Story = {};
