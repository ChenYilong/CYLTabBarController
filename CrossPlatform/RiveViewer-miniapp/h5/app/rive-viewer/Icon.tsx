import type { CSSProperties } from "react";
import { publicAssetUrl } from "../../lib/public-base";

export type IconName =
  | "archive"
  | "arrow-counter-clockwise"
  | "arrow-left"
  | "arrow-right"
  | "arrow-square-out"
  | "arrows-in-simple"
  | "arrows-out-simple"
  | "caret-down"
  | "check"
  | "chat-circle-dots"
  | "cloud-arrow-up"
  | "cloud-check"
  | "cloud-x"
  | "copy-simple"
  | "desktop"
  | "download-simple"
  | "gauge"
  | "keyboard"
  | "link-simple"
  | "pause"
  | "pencil-simple"
  | "play"
  | "plus"
  | "share-network"
  | "speaker-high"
  | "speaker-slash"
  | "trash"
  | "wechat-logo"
  | "x";

type IconStyle = CSSProperties & { "--icon-url": string };

export function Icon({
  name,
  size = 18,
  className = "",
}: {
  name: IconName;
  size?: number;
  className?: string;
}) {
  return (
    <span
      className={`app-icon ${className}`}
      style={{
        width: size,
        height: size,
        "--icon-url": `url(${publicAssetUrl(`icons/${name}.svg`)})`,
      } as IconStyle}
      aria-hidden="true"
    />
  );
}
