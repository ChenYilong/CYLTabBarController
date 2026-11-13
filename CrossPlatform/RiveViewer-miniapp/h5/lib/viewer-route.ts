function normalizeBasePath(basePath: string): string {
  const withLeadingSlash = basePath.startsWith("/") ? basePath : `/${basePath}`;
  return withLeadingSlash.endsWith("/") ? withLeadingSlash : `${withLeadingSlash}/`;
}

const SHARE_CODE_PATTERN = /^[0-9A-Za-z]{3}$/;
const RESERVED_SHARE_CODES = new Set(["api"]);

export function isHostedShareCode(code: string): boolean {
  return SHARE_CODE_PATTERN.test(code) && !RESERVED_SHARE_CODES.has(code.toLowerCase());
}

function codeFromCandidate(pathname: string): string | null {
  const matched = pathname.match(/^\/(?:s\/)?([^/]+)\/?$/);
  if (!matched) return null;
  try {
    const code = decodeURIComponent(matched[1]);
    return isHostedShareCode(code) ? code : null;
  } catch {
    return null;
  }
}

export function shareCodeFromPath(pathname: string, basePath = "/"): string | null {
  const directCode = codeFromCandidate(pathname);
  if (directCode) return directCode;

  const normalizedBase = normalizeBasePath(basePath);
  if (normalizedBase === "/" || !pathname.startsWith(normalizedBase)) return null;
  return codeFromCandidate(`/${pathname.slice(normalizedBase.length)}`);
}

export function hostedSharePath(code: string, basePath = "/"): string {
  if (!isHostedShareCode(code)) throw new Error("分享码必须是三位 Base62 且不能使用保留码");
  return `${normalizeBasePath(basePath)}${code}`;
}

export function hostedShareUrl(code: string, basePath = "/"): string {
  const path = hostedSharePath(code, basePath);
  if (typeof window === "undefined") return path;
  return new URL(path, window.location.origin).toString();
}

export function viewerHomePath(basePath = "/"): string {
  return normalizeBasePath(basePath);
}
