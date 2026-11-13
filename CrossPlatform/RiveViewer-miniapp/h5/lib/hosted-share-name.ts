import type { HostedFileVersion, HostedShare } from "./hosted-api";

export function hostedShareName(
  share: Pick<HostedShare, "filename" | "customName">,
  version?: Pick<HostedFileVersion, "filename"> | null,
): string {
  return share.customName || version?.filename || share.filename;
}
