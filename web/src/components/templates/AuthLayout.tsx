import { type FC, type ReactNode } from 'react';

interface AuthLayoutProps {
  children: ReactNode;
}

export const AuthLayout: FC<AuthLayoutProps> = ({ children }) => {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div>
          <h1 className="text-center text-3xl font-bold text-gray-900">
            MunServ
          </h1>
          <p className="mt-2 text-center text-sm text-gray-600">
            Municipal Service Admin Portal
          </p>
        </div>
        <div className="bg-white py-8 px-4 shadow-lg rounded-lg sm:px-10">
          {children}
        </div>
      </div>
    </div>
  );
};
