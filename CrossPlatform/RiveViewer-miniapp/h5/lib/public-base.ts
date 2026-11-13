const PUBLIC_BASE = import.meta.env.BASE_URL.endsWith("/")
  ? import.meta.env.BASE_URL
  : `${import.meta.env.BASE_URL}/`;

export function publicAssetUrl(path: string): string {
  return `${PUBLIC_BASE}${path.replace(/^\/+/, "")}`;
}
