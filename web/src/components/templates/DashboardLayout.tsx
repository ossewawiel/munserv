import { type FC, type ReactNode, useState, useCallback } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { clsx } from 'clsx';

import { useLogout } from '@/features/auth/hooks';
import { Button } from '@/components/atoms/Button';

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
  const navigate = useNavigate();
  const logout = useLogout();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const handleLogout = useCallback(() => {
    logout.mutate(undefined, {
      onSuccess: () => {
        navigate('/login');
      },
      onError: () => {
        // Even if API call fails, clear local state and redirect
        localStorage.removeItem('accessToken');
        localStorage.removeItem('refreshToken');
        localStorage.removeItem('admin');
        navigate('/login');
      },
    });
  }, [logout, navigate]);

  const toggleMobileMenu = useCallback(() => {
    setMobileMenuOpen((prev) => !prev);
  }, []);

  const closeMobileMenu = useCallback(() => {
    setMobileMenuOpen(false);
  }, []);

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
              {/* Desktop navigation */}
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
            <div className="flex items-center gap-2">
              {/* Mobile menu button */}
              <button
                type="button"
                onClick={toggleMobileMenu}
                className="inline-flex items-center justify-center rounded-md p-2 text-text-muted hover:bg-surface-hover hover:text-text sm:hidden"
                aria-expanded={mobileMenuOpen}
              >
                <span className="sr-only">Open main menu</span>
                {mobileMenuOpen ? (
                  <svg className="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                ) : (
                  <svg className="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
                  </svg>
                )}
              </button>
              {/* Logout button */}
              <Button
                variant="secondary"
                size="sm"
                onClick={handleLogout}
                isLoading={logout.isPending}
                className="hidden sm:inline-flex"
              >
                {t('auth.logout')}
              </Button>
            </div>
          </div>
        </div>

        {/* Mobile menu */}
        {mobileMenuOpen && (
          <div className="sm:hidden">
            <div className="space-y-1 px-4 pb-3 pt-2">
              {navItems.map((item) => (
                <Link
                  key={item.href}
                  to={item.href}
                  onClick={closeMobileMenu}
                  className={clsx(
                    'block rounded-md px-3 py-2 text-base font-medium',
                    location.pathname === item.href
                      ? 'bg-primary-100 text-primary-700'
                      : 'text-text-muted hover:bg-surface-hover hover:text-text'
                  )}
                >
                  {t(item.labelKey)}
                </Link>
              ))}
              <button
                type="button"
                onClick={handleLogout}
                className="mt-2 block w-full rounded-md px-3 py-2 text-left text-base font-medium text-danger-600 hover:bg-danger-50"
              >
                {t('auth.logout')}
              </button>
            </div>
          </div>
        )}
      </header>

      {/* Main content */}
      <main className="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
        {children}
      </main>
    </div>
  );
};
