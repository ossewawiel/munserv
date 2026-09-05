import { type FC, useState, useCallback, useRef, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import IconButton from '@mui/material/IconButton';
import Dialog from '@mui/material/Dialog';
import DialogContent from '@mui/material/DialogContent';
import ButtonBase from '@mui/material/ButtonBase';
import ChevronLeftIcon from '@mui/icons-material/ChevronLeft';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import CloseIcon from '@mui/icons-material/Close';

interface PhotoCarouselProps {
  photos: string[];
  alt?: string;
}

export const PhotoCarousel: FC<PhotoCarouselProps> = ({
  photos,
  alt = 'Photo',
}) => {
  const { t } = useTranslation();
  const [lightboxIndex, setLightboxIndex] = useState<number | null>(null);
  const [showLeftArrow, setShowLeftArrow] = useState(false);
  const [showRightArrow, setShowRightArrow] = useState(false);
  const scrollContainerRef = useRef<HTMLDivElement>(null);

  const checkScrollButtons = useCallback(() => {
    const container = scrollContainerRef.current;
    if (!container) return;

    const { scrollLeft, scrollWidth, clientWidth } = container;
    setShowLeftArrow(scrollLeft > 0);
    setShowRightArrow(scrollLeft + clientWidth < scrollWidth - 1);
  }, []);

  useEffect(() => {
    checkScrollButtons();
    window.addEventListener('resize', checkScrollButtons);
    return () => window.removeEventListener('resize', checkScrollButtons);
  }, [checkScrollButtons, photos.length]);

  const handleScroll = useCallback(() => {
    checkScrollButtons();
  }, [checkScrollButtons]);

  const handleScrollLeft = useCallback(() => {
    const container = scrollContainerRef.current;
    if (!container) return;
    container.scrollBy({ left: -150, behavior: 'smooth' });
  }, []);

  const handleScrollRight = useCallback(() => {
    const container = scrollContainerRef.current;
    if (!container) return;
    container.scrollBy({ left: 150, behavior: 'smooth' });
  }, []);

  const handleOpenLightbox = useCallback((index: number) => {
    setLightboxIndex(index);
  }, []);

  const handleCloseLightbox = useCallback(() => {
    setLightboxIndex(null);
  }, []);

  const handleLightboxPrevious = useCallback(() => {
    setLightboxIndex((prev) => {
      if (prev === null) return null;
      return prev > 0 ? prev - 1 : photos.length - 1;
    });
  }, [photos.length]);

  const handleLightboxNext = useCallback(() => {
    setLightboxIndex((prev) => {
      if (prev === null) return null;
      return prev < photos.length - 1 ? prev + 1 : 0;
    });
  }, [photos.length]);

  if (photos.length === 0) {
    return (
      <Box
        sx={{
          display: 'flex',
          height: '100%',
          alignItems: 'center',
          justifyContent: 'center',
          borderRadius: 2,
          border: '1px dashed',
          borderColor: 'divider',
          bgcolor: 'background.paper',
        }}
      >
        <Typography variant="body2" sx={{
          color: "text.secondary"
        }}>
          {t('common.noResults')}
        </Typography>
      </Box>
    );
  }

  return (
    <>
      <Box sx={{ position: 'relative', height: '100%' }}>
        {/* Left scroll button - always visible, disabled when can't scroll */}
        <IconButton
          onClick={handleScrollLeft}
          aria-label={t('common.previous')}
          size="small"
          disabled={!showLeftArrow}
          sx={{
            position: 'absolute',
            left: 0,
            top: '50%',
            transform: 'translateY(-50%)',
            zIndex: 1,
            bgcolor: 'rgba(0, 0, 0, 0.6)',
            color: 'white',
            '&:hover': {
              bgcolor: 'rgba(0, 0, 0, 0.8)',
            },
            '&.Mui-disabled': {
              bgcolor: 'rgba(0, 0, 0, 0.3)',
              color: 'rgba(255, 255, 255, 0.5)',
            },
          }}
        >
          <ChevronLeftIcon fontSize="small" />
        </IconButton>

        {/* Photos container */}
        <Box
          ref={scrollContainerRef}
          onScroll={handleScroll}
          sx={{
            display: 'flex',
            gap: 1,
            height: '100%',
            overflowX: 'auto',
            overflowY: 'hidden',
            scrollbarWidth: 'none',
            '&::-webkit-scrollbar': { display: 'none' },
            // Center photos horizontally
            justifyContent: 'center',
            // Add padding for arrow buttons
            px: 4,
          }}
        >
          {photos.map((photo, index) => (
            <ButtonBase
              key={photo}
              onClick={() => handleOpenLightbox(index)}
              role="tab"
              aria-selected={lightboxIndex === index}
              sx={{
                height: '100%',
                aspectRatio: '1',
                flexShrink: 0,
                borderRadius: 2,
                overflow: 'hidden',
                '&:focus-visible': {
                  outline: 2,
                  outlineOffset: 2,
                  outlineColor: 'primary.main',
                },
              }}
            >
              <Box
                component="img"
                src={photo}
                alt={`${alt} ${index + 1}`}
                sx={{
                  width: '100%',
                  height: '100%',
                  objectFit: 'cover',
                }}
              />
            </ButtonBase>
          ))}
        </Box>

        {/* Right scroll button - always visible, disabled when can't scroll */}
        <IconButton
          onClick={handleScrollRight}
          aria-label={t('common.next')}
          size="small"
          disabled={!showRightArrow}
          sx={{
            position: 'absolute',
            right: 0,
            top: '50%',
            transform: 'translateY(-50%)',
            zIndex: 1,
            bgcolor: 'rgba(0, 0, 0, 0.6)',
            color: 'white',
            '&:hover': {
              bgcolor: 'rgba(0, 0, 0, 0.8)',
            },
            '&.Mui-disabled': {
              bgcolor: 'rgba(0, 0, 0, 0.3)',
              color: 'rgba(255, 255, 255, 0.5)',
            },
          }}
        >
          <ChevronRightIcon fontSize="small" />
        </IconButton>
      </Box>

      {/* Lightbox Dialog */}
      <Dialog
        open={lightboxIndex !== null}
        onClose={handleCloseLightbox}
        maxWidth="lg"
        fullWidth
        slotProps={{
          paper: {
            sx: {
              bgcolor: 'transparent',
              boxShadow: 'none',
              maxHeight: '90vh',
            },
          }
        }}
      >
        <DialogContent
          sx={{
            p: 0,
            position: 'relative',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
          }}
        >
          {/* Close button */}
          <IconButton
            onClick={handleCloseLightbox}
            aria-label={t('common.close')}
            sx={{
              position: 'absolute',
              right: 8,
              top: 8,
              bgcolor: 'rgba(0, 0, 0, 0.5)',
              color: 'white',
              zIndex: 1,
              '&:hover': {
                bgcolor: 'rgba(0, 0, 0, 0.7)',
              },
            }}
          >
            <CloseIcon />
          </IconButton>

          {/* Photo */}
          {lightboxIndex !== null && (
            <Box
              component="img"
              src={photos[lightboxIndex]}
              alt={`${alt} ${lightboxIndex + 1}`}
              sx={{
                maxWidth: '100%',
                maxHeight: '80vh',
                objectFit: 'contain',
                borderRadius: 2,
              }}
            />
          )}

          {/* Navigation and counter */}
          {photos.length > 1 && (
            <Box
              sx={{
                display: 'flex',
                alignItems: 'center',
                gap: 2,
                mt: 2,
              }}
            >
              <IconButton
                onClick={handleLightboxPrevious}
                aria-label={t('common.previous')}
                sx={{
                  bgcolor: 'rgba(0, 0, 0, 0.5)',
                  color: 'white',
                  '&:hover': {
                    bgcolor: 'rgba(0, 0, 0, 0.7)',
                  },
                }}
              >
                <ChevronLeftIcon />
              </IconButton>

              <Typography
                variant="body2"
                sx={{
                  color: 'white',
                  bgcolor: 'rgba(0, 0, 0, 0.5)',
                  px: 2,
                  py: 0.5,
                  borderRadius: 1,
                }}
              >
                {lightboxIndex !== null ? lightboxIndex + 1 : 0} of {photos.length}
              </Typography>

              <IconButton
                onClick={handleLightboxNext}
                aria-label={t('common.next')}
                sx={{
                  bgcolor: 'rgba(0, 0, 0, 0.5)',
                  color: 'white',
                  '&:hover': {
                    bgcolor: 'rgba(0, 0, 0, 0.7)',
                  },
                }}
              >
                <ChevronRightIcon />
              </IconButton>
            </Box>
          )}
        </DialogContent>
      </Dialog>
    </>
  );
};
