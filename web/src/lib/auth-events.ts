/**
 * Custom event emitter for authentication events.
 * Used to communicate auth state changes (like session expiration)
 * from the API layer to React components without tight coupling.
 */

export type AuthEventType = 'session-expired';

export interface AuthEvent {
  type: AuthEventType;
  timestamp: number;
}

type AuthEventListener = (event: AuthEvent) => void;

class AuthEventEmitter {
  private listeners: AuthEventListener[] = [];

  subscribe(listener: AuthEventListener): () => void {
    this.listeners.push(listener);
    return () => {
      this.listeners = this.listeners.filter((l) => l !== listener);
    };
  }

  emit(type: AuthEventType): void {
    const event: AuthEvent = {
      type,
      timestamp: Date.now(),
    };
    this.listeners.forEach((listener) => listener(event));
  }
}

export const authEvents = new AuthEventEmitter();
