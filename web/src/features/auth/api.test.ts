import { describe, it, expect, beforeEach } from 'vitest';
import { http, HttpResponse } from 'msw';
import { server } from '@/test/mocks/server';
import { authApi } from './api';

describe('authApi', () => {
  beforeEach(() => {
    server.resetHandlers();
  });

  describe('getSectors', () => {
    it('should fetch sectors successfully', async () => {
      const sectors = await authApi.getSectors();

      expect(sectors).toHaveLength(2);
      expect(sectors[0]).toEqual({
        id: 'sector-1',
        name: 'Ward 42',
        center: { lat: -26.2041, lng: 28.0473 },
      });
    });

    it('should handle empty sectors list', async () => {
      server.use(
        http.get('*/sectors', () => {
          return HttpResponse.json({ items: [] });
        })
      );

      const sectors = await authApi.getSectors();
      expect(sectors).toHaveLength(0);
    });

    it('should throw error on server failure', async () => {
      server.use(
        http.get('*/sectors', () => {
          return HttpResponse.json(
            { message: 'Internal server error' },
            { status: 500 }
          );
        })
      );

      await expect(authApi.getSectors()).rejects.toThrow();
    });
  });

  describe('registerMember', () => {
    const validRegistration = {
      email: 'newuser@example.com',
      firstName: 'John',
      surname: 'Doe',
      phone: '+27123456789',
      address: '123 Test Street',
      latitude: -26.2041,
      longitude: 28.0473,
      sectorId: 'sector-1',
    };

    it('should register a new member successfully', async () => {
      const response = await authApi.registerMember(validRegistration);

      expect(response).toEqual({
        message: 'Registration submitted successfully',
        memberId: 'member-new-1',
      });
    });

    it('should handle duplicate email error', async () => {
      const duplicateEmail = {
        ...validRegistration,
        email: 'existing@example.com',
      };

      await expect(authApi.registerMember(duplicateEmail)).rejects.toMatchObject({
        response: { status: 409 },
      });
    });

    it('should handle validation errors', async () => {
      const invalidData = {
        ...validRegistration,
        email: '',
        firstName: '',
      };

      await expect(authApi.registerMember(invalidData)).rejects.toMatchObject({
        response: { status: 400 },
      });
    });

    it('should throw error on server failure', async () => {
      server.use(
        http.post('*/auth/register/web', () => {
          return HttpResponse.json(
            { message: 'Internal server error' },
            { status: 500 }
          );
        })
      );

      await expect(authApi.registerMember(validRegistration)).rejects.toThrow();
    });
  });

  describe('login', () => {
    it('should login admin successfully', async () => {
      const response = await authApi.login({
        email: 'admin@ward42.example.com',
        password: 'admin123',
      });

      expect(response.tokens).toBeDefined();
      expect(response.tokens.accessToken).toBe('mock-access-token');
      expect(response.profile.admin.email).toBe('admin@ward42.example.com');
    });

    it('should handle invalid credentials', async () => {
      await expect(
        authApi.login({
          email: 'wrong@example.com',
          password: 'wrongpassword',
        })
      ).rejects.toMatchObject({
        response: { status: 401 },
      });
    });
  });
});
