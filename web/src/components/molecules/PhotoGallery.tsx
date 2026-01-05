import { type FC, useState, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { clsx } from 'clsx';

import { Modal } from '@/components/atoms/Modal';

interface PhotoGalleryProps {
  photos: string[];
  alt?: string;
  className?: string;
}

export const PhotoGallery: FC<PhotoGalleryProps> = ({
  photos,
  alt = 'Photo',
  className,
}) => {
  const { t } = useTranslation();
  const [selectedPhoto, setSelectedPhoto] = useState<string | null>(null);

  const handleClose = useCallback(() => {
    setSelectedPhoto(null);
  }, []);

  if (photos.length === 0) {
    return (
      <div className="flex h-32 items-center justify-center rounded-lg border border-dashed border-border bg-surface">
        <p className="text-sm text-text-muted">{t('common.noResults')}</p>
      </div>
    );
  }

  return (
    <>
      <div
        className={clsx(
          'grid gap-2',
          photos.length === 1
            ? 'grid-cols-1'
            : photos.length === 2
              ? 'grid-cols-2'
              : 'grid-cols-2 sm:grid-cols-3',
          className
        )}
      >
        {photos.map((photo, index) => (
          <button
            key={photo}
            onClick={() => setSelectedPhoto(photo)}
            className="group relative aspect-square overflow-hidden rounded-lg border border-border focus:outline-none focus:ring-2 focus:ring-primary-500"
          >
            <img
              src={photo}
              alt={`${alt} ${index + 1}`}
              className="h-full w-full object-cover transition-transform group-hover:scale-105"
            />
            <div className="absolute inset-0 bg-black/0 transition-colors group-hover:bg-black/10" />
          </button>
        ))}
      </div>

      <Modal isOpen={!!selectedPhoto} onClose={handleClose} size="lg">
        {selectedPhoto && (
          <div className="relative">
            <img
              src={selectedPhoto}
              alt={alt}
              className="w-full rounded-lg"
            />
          </div>
        )}
      </Modal>
    </>
  );
};
