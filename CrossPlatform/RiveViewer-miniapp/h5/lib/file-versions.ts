import type { HostedFileVersion, HostedShare } from "./hosted-api";

export function hostedVersions(share: HostedShare | null): HostedFileVersion[] {
  if (!share) return [];
  if (share.versions?.length) return share.versions;
  return [{
    id: share.currentVersionId || share.etag,
    name: "版本 1",
    filename: share.filename,
    format: share.format,
    size: share.size,
    sha256: share.sha256,
    etag: share.etag,
    createdAt: share.createdAt,
  }];
}

export function selectedHostedVersion(
  share: HostedShare | null,
  requestedVersionId = "",
): HostedFileVersion | null {
  const versions = hostedVersions(share);
  return versions.find((version) => version.id === requestedVersionId)
    || versions.find((version) => version.id === share?.currentVersionId)
    || versions.at(-1)
    || null;
}

export function formatHostedVersionDate(value: string): string {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return new Intl.DateTimeFormat("zh-CN", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).format(date);
}
