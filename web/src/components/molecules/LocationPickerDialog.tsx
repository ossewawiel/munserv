import { type FC, useState, useCallback, useEffect, useMemo, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import { MapContainer, TileLayer, Marker, useMapEvents, useMap } from 'react-leaflet';
import L from 'leaflet';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Alert from '@mui/material/Alert';
import CircularProgress from '@mui/material/CircularProgress';
import MyLocationIcon from '@mui/icons-material/MyLocation';

import { Button } from '@/components/atoms/Button';

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

export interface LocationPickerResult {
  latitude: number;
  longitude: number;
  address: string;
}

interface LocationPickerDialogProps {
  open: boolean;
  onClose: () => void;
  onConfirm: (result: LocationPickerResult) => void;
  initialLatitude?: number;
  initialLongitude?: number;
}

// Default center: Johannesburg, South Africa
const DEFAULT_CENTER: L.LatLngTuple = [-26.2041, 28.0473];
const DEFAULT_ZOOM = 15;

// Nominatim reverse geocoding (free, no API key needed)
async function reverseGeocode(lat: number, lng: number): Promise<string> {
  try {
    const response = await fetch(
      `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&zoom=18&addressdetails=1`,
      {
        headers: {
          'Accept-Language': 'en',
          'User-Agent': 'MunServ-WebApp/1.0',
        },
      }
    );

    if (!response.ok) {
      throw new Error('Geocoding failed');
    }

    const data = await response.json();
    return data.display_name || `${lat.toFixed(6)}, ${lng.toFixed(6)}`;
  } catch {
    return `${lat.toFixed(6)}, ${lng.toFixed(6)}`;
  }
}

// Component to handle map click events
interface MapClickHandlerProps {
  onLocationSelect: (lat: number, lng: number) => void;
}

function MapClickHandler({ onLocationSelect }: MapClickHandlerProps) {
  useMapEvents({
    click(e) {
      onLocationSelect(e.latlng.lat, e.latlng.lng);
    },
  });
  return null;
}

// Component to recenter map
interface MapRecenterProps {
  position: L.LatLngTuple | null;
}

function MapRecenter({ position }: MapRecenterProps) {
  const map = useMap();

  useEffect(() => {
    if (position) {
      map.setView(position, map.getZoom());
    }
  }, [map, position]);

  return null;
}

// Draggable marker component
interface DraggableMarkerProps {
  position: L.LatLngTuple;
  onDragEnd: (lat: number, lng: number) => void;
}

function DraggableMarker({ position, onDragEnd }: DraggableMarkerProps) {
  const markerRef = useRef<L.Marker>(null);

  const eventHandlers = useMemo(
    () => ({
      dragend() {
        const marker = markerRef.current;
        if (marker) {
          const latlng = marker.getLatLng();
          onDragEnd(latlng.lat, latlng.lng);
        }
      },
    }),
    [onDragEnd]
  );

  return (
    <Marker
      draggable
      eventHandlers={eventHandlers}
      position={position}
      ref={markerRef}
    />
  );
}

export const LocationPickerDialog: FC<LocationPickerDialogProps> = ({
  open,
  onClose,
  onConfirm,
  initialLatitude,
  initialLongitude,
}) => {
  const { t } = useTranslation();

  const [markerPosition, setMarkerPosition] = useState<L.LatLngTuple | null>(null);
  const [selectedAddress, setSelectedAddress] = useState<string>('');
  const [isGettingLocation, setIsGettingLocation] = useState(false);
  const [isGeocoding, setIsGeocoding] = useState(false);
  const [locationError, setLocationError] = useState<string | null>(null);
  const [mapKey, setMapKey] = useState(0);

  // Handle location selection (from click or geolocation)
  const handleLocationSelect = useCallback(async (lat: number, lng: number) => {
    const position: L.LatLngTuple = [lat, lng];
    setMarkerPosition(position);
    setLocationError(null);
    setIsGeocoding(true);

    const address = await reverseGeocode(lat, lng);
    setSelectedAddress(address);
    setIsGeocoding(false);
  }, []);

  // Reset dialog state when it opens
  const handleDialogEnter = useCallback(() => {
    setMapKey((prev) => prev + 1);
    setMarkerPosition(null);
    setSelectedAddress('');
    setLocationError(null);
    setIsGeocoding(false);

    // If initial coordinates are provided, set them
    if (initialLatitude && initialLongitude) {
      handleLocationSelect(initialLatitude, initialLongitude);
    }
  }, [initialLatitude, initialLongitude, handleLocationSelect]);

  const handleGetCurrentLocation = useCallback(() => {
    if (!navigator.geolocation) {
      setLocationError(t('auth.locationError'));
      return;
    }

    setIsGettingLocation(true);
    setLocationError(null);

    navigator.geolocation.getCurrentPosition(
      (position) => {
        handleLocationSelect(position.coords.latitude, position.coords.longitude);
        setIsGettingLocation(false);
      },
      () => {
        setLocationError(t('auth.locationError'));
        setIsGettingLocation(false);
      },
      { enableHighAccuracy: true, timeout: 10000 }
    );
  }, [t, handleLocationSelect]);

  const handleConfirm = useCallback(() => {
    if (markerPosition && selectedAddress) {
      onConfirm({
        latitude: markerPosition[0],
        longitude: markerPosition[1],
        address: selectedAddress,
      });
    }
  }, [markerPosition, selectedAddress, onConfirm]);

  const center = useMemo((): L.LatLngTuple => {
    if (initialLatitude && initialLongitude) {
      return [initialLatitude, initialLongitude];
    }
    return DEFAULT_CENTER;
  }, [initialLatitude, initialLongitude]);

  const isConfirmDisabled = !markerPosition || !selectedAddress || isGeocoding;

  return (
    <Dialog
      open={open}
      onClose={onClose}
      maxWidth="md"
      fullWidth
      slotProps={{
        transition: {
          onEnter: handleDialogEnter,
        },

        paper: {
          sx: { maxHeight: '90vh' },
        }
      }}>
      <DialogTitle>{t('auth.selectLocation')}</DialogTitle>
      <DialogContent>
        <Typography
          variant="body2"
          sx={{
            color: "text.secondary",
            mb: 2
          }}>
          {t('auth.selectLocationHelp')}
        </Typography>

        {locationError && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {locationError}
          </Alert>
        )}

        <Box sx={{ mb: 2 }}>
          <Button
            variant="secondary"
            onClick={handleGetCurrentLocation}
            disabled={isGettingLocation}
            startIcon={isGettingLocation ? <CircularProgress size={16} /> : <MyLocationIcon />}
          >
            {isGettingLocation ? t('auth.gettingLocation') : t('auth.currentLocation')}
          </Button>
        </Box>

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
            center={center}
            zoom={DEFAULT_ZOOM}
            style={{ height: '100%', width: '100%' }}
          >
            <TileLayer
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            />
            <MapClickHandler onLocationSelect={handleLocationSelect} />
            {markerPosition && (
              <>
                <DraggableMarker
                  position={markerPosition}
                  onDragEnd={handleLocationSelect}
                />
                <MapRecenter position={markerPosition} />
              </>
            )}
          </MapContainer>
        </Box>

        {(selectedAddress || isGeocoding) && (
          <Box sx={{ mt: 2, p: 2, bgcolor: 'action.hover', borderRadius: 1 }}>
            <Typography variant="caption" sx={{
              color: "text.secondary"
            }}>
              {t('auth.selectedAddress')}
            </Typography>
            {isGeocoding ? (
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <CircularProgress size={16} />
                <Typography variant="body2" sx={{
                  color: "text.secondary"
                }}>
                  {t('auth.gettingAddress')}
                </Typography>
              </Box>
            ) : (
              <Typography variant="body1">{selectedAddress}</Typography>
            )}
          </Box>
        )}
      </DialogContent>
      <DialogActions sx={{ px: 3, pb: 2 }}>
        <Button variant="ghost" onClick={onClose}>
          {t('common.cancel')}
        </Button>
        <Button
          variant="primary"
          onClick={handleConfirm}
          disabled={isConfirmDisabled}
        >
          {t('auth.confirmLocation')}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default LocationPickerDialog;
