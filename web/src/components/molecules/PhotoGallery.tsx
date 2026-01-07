import { type FC, useState, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import ImageList from '@mui/material/ImageList';
import ImageListItem from '@mui/material/ImageListItem';
import ButtonBase from '@mui/material/ButtonBase';

import { Modal } from '@/components/atoms/Modal';

interface PhotoGalleryProps {
  photos: string[];
  alt?: string;
}

export const PhotoGallery: FC<PhotoGalleryProps> = ({
  photos,
  alt = 'Photo',
}) => {
  const { t } = useTranslation();
  const [selectedPhoto, setSelectedPhoto] = useState<string | null>(null);

  const handleClose = useCallback(() => {
    setSelectedPhoto(null);
  }, []);

  const getCols = (count: number): number => {
    if (count === 1) return 1;
    if (count === 2) return 2;
    return 3;
  };

  if (photos.length === 0) {
    return (
      <Box
        sx={{
          display: 'flex',
          height: 128,
          alignItems: 'center',
          justifyContent: 'center',
          borderRadius: 2,
          border: '1px dashed',
          borderColor: 'divider',
          bgcolor: 'var(--munserv-palette-background-paper)',
        }}
      >
        <Typography variant="body2" color="text.secondary">
          {t('common.noResults')}
        </Typography>
      </Box>
    );
  }

  return (
    <>
      <ImageList cols={getCols(photos.length)} gap={8}>
        {photos.map((photo, index) => (
          <ImageListItem key={photo}>
            <ButtonBase
              onClick={() => setSelectedPhoto(photo)}
              sx={{
                width: '100%',
                aspectRatio: '1',
                overflow: 'hidden',
                borderRadius: 2,
                border: 1,
                borderColor: 'divider',
                '&:focus-visible': {
                  outline: 2,
                  outlineOffset: 2,
                  outlineColor: 'primary.main',
                },
                '& img': {
                  width: '100%',
                  height: '100%',
                  objectFit: 'cover',
                  transition: 'transform 0.2s',
                },
                '&:hover img': {
                  transform: 'scale(1.05)',
                },
                '&:hover::after': {
                  content: '""',
                  position: 'absolute',
                  inset: 0,
                  bgcolor: 'action.hover',
                },
              }}
            >
              <img
                src={photo}
                alt={`${alt} ${index + 1}`}
                loading="lazy"
              />
            </ButtonBase>
          </ImageListItem>
        ))}
      </ImageList>

      <Modal isOpen={!!selectedPhoto} onClose={handleClose} size="lg">
        {selectedPhoto && (
          <Box sx={{ position: 'relative' }}>
            <Box
              component="img"
              src={selectedPhoto}
              alt={alt}
              sx={{
                width: '100%',
                borderRadius: 2,
              }}
            />
          </Box>
        )}
      </Modal>
    </>
  );
};
