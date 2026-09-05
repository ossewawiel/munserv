import { type FC, useState, useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { MapContainer, TileLayer, Marker } from 'react-leaflet';
import L from 'leaflet';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';
import ButtonBase from '@mui/material/ButtonBase';
import PlaceIcon from '@mui/icons-material/Place';

import { Button } from '@/components/atoms/Button';
import type { GeoPoint } from '@/shared/types/common';

// Import Leaflet CSS
import 'leaflet/dist/leaflet.css';

// Fix for default marker icon in Leaflet with bundlers
import markerIcon2x from 'leaflet/dist/images/marker-icon-2x.png';
import markerIcon from 'leaflet/dist/images/marker-icon.png';
import markerShadow from 'leaflet/dist/images/marker-shadow.png';

// Fix Leaflet's default icon path issue
delete (L.Icon.Default.prototype as unknown as Record<string, unknown>)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconUrl: markerIcon,
  iconRetinaUrl: markerIcon2x,
  shadowUrl: markerShadow,
});

interface LocationMapPreviewProps {
  location: GeoPoint;
  address?: string | null;
}

const DEFAULT_ZOOM = 15;
const DIALOG_ZOOM = 16;

export const LocationMapPreview: FC<LocationMapPreviewProps> = ({
  location,
  address,
}) => {
  const { t } = useTranslation();
  const [dialogOpen, setDialogOpen] = useState(false);
  const [mapKey, setMapKey] = useState(0);

  const position = useMemo(
    (): L.LatLngTuple => [location.latitude, location.longitude],
    [location.latitude, location.longitude]
  );

  const displayAddress = address || `${location.latitude.toFixed(4)}, ${location.longitude.toFixed(4)}`;

  const handleOpenDialog = useCallback(() => {
    setMapKey((prev) => prev + 1);
    setDialogOpen(true);
  }, []);

  const handleCloseDialog = useCallback(() => {
    setDialogOpen(false);
  }, []);

  return (
    <>
      <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
        {/* Clickable map preview - maintains 4:3 aspect ratio */}
        <ButtonBase
          onClick={handleOpenDialog}
          sx={{
            width: '100%',
            aspectRatio: '4/3',
            borderRadius: 2,
            overflow: 'hidden',
            display: 'block',
            position: 'relative',
            '&:focus-visible': {
              outline: 2,
              outlineOffset: 2,
              outlineColor: 'primary.main',
            },
          }}
        >
          <MapContainer
            center={position}
            zoom={DEFAULT_ZOOM}
            style={{ height: '100%', width: '100%' }}
            zoomControl={false}
            dragging={false}
            scrollWheelZoom={false}
            doubleClickZoom={false}
            touchZoom={false}
          >
            <TileLayer
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            />
            <Marker position={position} />
          </MapContainer>

          {/* Overlay hint */}
          <Box
            sx={{
              position: 'absolute',
              bottom: 0,
              left: 0,
              right: 0,
              bgcolor: 'rgba(0, 0, 0, 0.6)',
              color: 'white',
              py: 0.75,
              px: 1.5,
              display: 'flex',
              alignItems: 'center',
              gap: 0.5,
            }}
          >
            <PlaceIcon sx={{ fontSize: 16 }} />
            <Typography variant="caption" sx={{ fontSize: '0.7rem' }}>
              {t('issues.viewOnMap')}
            </Typography>
          </Box>
        </ButtonBase>
      </Box>

      {/* Interactive Map Dialog */}
      <Dialog
        open={dialogOpen}
        onClose={handleCloseDialog}
        maxWidth="md"
        fullWidth
        slotProps={{
          paper: {
            sx: { maxHeight: '90vh' },
          }
        }}
      >
        <DialogTitle>{t('issues.location')}</DialogTitle>
        <DialogContent>
          <Typography
            variant="body2"
            sx={{
              color: "text.secondary",
              mb: 2
            }}>
            {displayAddress}
          </Typography>

          <Box
            sx={{
              width: '100%',
              height: 400,
              borderRadius: 1,
              overflow: 'hidden',
              border: 1,
              borderColor: 'divider',
            }}
          >
            <MapContainer
              key={mapKey}
              center={position}
              zoom={DIALOG_ZOOM}
              style={{ height: '100%', width: '100%' }}
            >
              <TileLayer
                attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
              />
              <Marker position={position} />
            </MapContainer>
          </Box>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button variant="secondary" onClick={handleCloseDialog}>
            {t('common.close')}
          </Button>
        </DialogActions>
      </Dialog>
    </>
  );
};
