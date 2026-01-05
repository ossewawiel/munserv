import { type FC, type ReactNode } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { clsx } from 'clsx';

interface NavItem {
  labelKey: string;
  href: string;
}

const navItems: NavItem[] = [
  { labelKey: 'nav.dashboard', href: '/' },
  { labelKey: 'nav.issues', href: '/issues' },
  { labelKey: 'nav.heatReport', href: '/reports/heat' },
  { labelKey: 'nav.members', href: '/members' },
];

interface DashboardLayoutProps {
  children: ReactNode;
}

export const DashboardLayout: FC<DashboardLayoutProps> = ({ children }) => {
  const { t } = useTranslation();
  const location = useLocation();

  return (
    <div className="min-h-screen bg-surface">
      {/* Header */}
      <header className="bg-background shadow-sm">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="flex h-16 justify-between">
            <div className="flex">
              <div className="flex flex-shrink-0 items-center">
                <h1 className="text-xl font-bold text-text">{t('common.appName')}</h1>
              </div>
              <nav className="hidden sm:ml-8 sm:flex sm:space-x-4">
                {navItems.map((item) => (
                  <Link
                    key={item.href}
                    to={item.href}
                    className={clsx(
                      'inline-flex items-center rounded-md px-3 py-2 text-sm font-medium',
                      location.pathname === item.href
                        ? 'bg-primary-100 text-primary-700'
                        : 'text-text-muted hover:bg-surface-hover hover:text-text'
                    )}
                  >
                    {t(item.labelKey)}
                  </Link>
                ))}
              </nav>
            </div>
            <div className="flex items-center">
              <button
                type="button"
                className="px-3 py-2 text-sm font-medium text-text-muted hover:text-text"
              >
                {t('auth.logout')}
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Main content */}
      <main className="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
        {children}
      </main>
    </div>
  );
};
