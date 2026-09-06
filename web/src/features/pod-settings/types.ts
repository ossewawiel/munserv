export interface PodSettings {
  name: string;
  displayName: string;
  logoUrl: string | null;
}

export interface UpdatePodSettingsRequest {
  name?: string;
  logoUrl?: string;
}
