import { type FC, type ReactNode } from 'react';
import { useTranslation } from 'react-i18next';

interface AuthLayoutProps {
  children: ReactNode;
}

export const AuthLayout: FC<AuthLayoutProps> = ({ children }) => {
  const { t } = useTranslation();

  return (
    <div className="min-h-screen flex items-center justify-center bg-surface py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div>
          <h1 className="text-center text-3xl font-bold text-text">
            {t('common.appName')}
          </h1>
          <p className="mt-2 text-center text-sm text-text-muted">
            Municipal Service Admin Portal
          </p>
        </div>
        <div className="bg-background py-8 px-4 shadow-lg rounded-lg sm:px-10 border border-border">
          {children}
        </div>
      </div>
    </div>
  );
};
