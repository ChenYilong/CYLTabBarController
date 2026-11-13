import type { HostedShare } from "./hosted-api";
import type { LibraryFile } from "./library";
import { hostedShareName } from "./hosted-share-name.ts";

export type UnifiedFileItem = {
  key: string;
  file: LibraryFile;
  localFile?: LibraryFile;
  hostedCode?: string;
  share?: HostedShare;
  activityAt: number;
};

function isLocalFile(file: LibraryFile): boolean {
  return file.id.startsWith("local-") && !file.hostedCode;
}

function validHostedCode(value: string | undefined): value is string {
  return Boolean(value && /^[0-9A-Za-z]{3}$/.test(value) && value.toLowerCase() !== "api");
}

function shareAsLibraryFile(share: HostedShare): LibraryFile {
  return {
    id: `hosted-${share.code}`,
    name: hostedShareName(share),
    size: share.size,
    format: share.format,
    updatedAt: Date.parse(share.createdAt) || Date.now(),
    hostedCode: share.code,
  };
}

export function mergeUnifiedFiles(
  libraryFiles: LibraryFile[],
  activeShares: HostedShare[],
  archivedShares: HostedShare[],
  publishedCodes: Record<string, string>,
): UnifiedFileItem[] {
  const activeByCode = new Map(activeShares.map((share) => [share.code, share]));
  const archivedCodes = new Set(archivedShares.map((share) => share.code));
  const merged = new Map<string, UnifiedFileItem>();

  const add = (candidate: UnifiedFileItem) => {
    const current = merged.get(candidate.key);
    if (!current) {
      merged.set(candidate.key, candidate);
      return;
    }
    const activityAt = Math.max(current.activityAt, candidate.activityAt);
    const localFile = current.localFile || candidate.localFile;
    const currentHasCover = Boolean(current.file.cover);
    const candidateHasCover = Boolean(candidate.file.cover);
    const preferredFile = localFile
      || (candidateHasCover && !currentHasCover ? candidate.file : current.file);
    merged.set(candidate.key, {
      ...current,
      ...candidate,
      file: { ...preferredFile, updatedAt: activityAt },
      localFile,
      hostedCode: candidate.hostedCode || current.hostedCode,
      share: candidate.share || current.share,
      activityAt,
    });
  };

  libraryFiles.forEach((file) => {
    if (isLocalFile(file)) {
      const mappedCode = publishedCodes[file.id];
      const hostedCode = validHostedCode(mappedCode) && !archivedCodes.has(mappedCode)
        ? mappedCode
        : undefined;
      const share = hostedCode ? activeByCode.get(hostedCode) : undefined;
      add({
        key: hostedCode ? `hosted-${hostedCode}` : file.id,
        file,
        localFile: file,
        hostedCode,
        share,
        activityAt: Math.max(file.updatedAt, share ? Date.parse(share.createdAt) || 0 : 0),
      });
      return;
    }

    const hostedCode = file.hostedCode;
    if (!validHostedCode(hostedCode) || archivedCodes.has(hostedCode)) return;
    const share = activeByCode.get(hostedCode);
    add({
      key: `hosted-${hostedCode}`,
      file,
      hostedCode,
      share,
      activityAt: Math.max(file.updatedAt, share ? Date.parse(share.createdAt) || 0 : 0),
    });
  });

  activeShares.forEach((share) => {
    const file = shareAsLibraryFile(share);
    add({
      key: `hosted-${share.code}`,
      file,
      hostedCode: share.code,
      share,
      activityAt: file.updatedAt,
    });
  });

  return [...merged.values()]
    .map((item) => ({
      ...item,
      file: {
        ...item.file,
        name: item.share ? hostedShareName(item.share) : item.file.name,
        updatedAt: item.activityAt,
      },
    }))
    .sort((left, right) => right.activityAt - left.activityAt);
}
