import { createRoot } from "react-dom/client";
import "../app/globals.css";
import { RiveViewerApp } from "../app/rive-viewer/RiveViewerApp";
import { shareCodeFromPath } from "../lib/viewer-route";

const root = document.getElementById("root");

if (!root) {
  throw new Error("缺少 H5 根节点");
}

const mode = ["/", "/beta/"].includes(import.meta.env.BASE_URL) ? "hosted" : "local";
const shareCode = mode === "hosted"
  ? shareCodeFromPath(window.location.pathname, import.meta.env.BASE_URL)
  : null;

createRoot(root).render(<RiveViewerApp mode={mode} shareCode={shareCode} />);
