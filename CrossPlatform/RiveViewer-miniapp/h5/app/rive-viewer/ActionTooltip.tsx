import { useEffect, useId, useLayoutEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";

/** One tooltip outside the preview's clipping and stacking contexts. */
export function ActionTooltip() {
  const [target, setTarget] = useState<HTMLElement | null>(null);
  const tooltipRef = useRef<HTMLDivElement>(null);
  const id = useId();

  useEffect(() => {
    const show = (event: Event) => {
      if (event instanceof PointerEvent && event.pointerType === "touch") return;
      const element = event.target instanceof Element ? event.target.closest<HTMLElement>("[data-shortcut-tip]") : null;
      setTarget(element);
    };
    const leave = (event: MouseEvent | FocusEvent) => {
      const next = event.relatedTarget instanceof Element ? event.relatedTarget.closest<HTMLElement>("[data-shortcut-tip]") : null;
      setTarget(next);
    };
    const close = () => setTarget(null);
    const escape = (event: KeyboardEvent) => { if (event.key === "Escape") close(); };
    document.addEventListener("pointerover", show);
    document.addEventListener("pointerout", leave);
    document.addEventListener("focusin", show);
    document.addEventListener("focusout", leave);
    document.addEventListener("pointerdown", close);
    window.addEventListener("keydown", escape, true);
    window.addEventListener("scroll", close, true);
    window.addEventListener("resize", close);
    return () => {
      document.removeEventListener("pointerover", show);
      document.removeEventListener("pointerout", leave);
      document.removeEventListener("focusin", show);
      document.removeEventListener("focusout", leave);
      document.removeEventListener("pointerdown", close);
      window.removeEventListener("keydown", escape, true);
      window.removeEventListener("scroll", close, true);
      window.removeEventListener("resize", close);
    };
  }, []);

  useLayoutEffect(() => {
    const tooltip = tooltipRef.current;
    if (!target || !tooltip) return;
    // The native top layer also escapes transformed ancestors and high-z canvases.
    tooltip.showPopover?.();
    const anchor = target.getBoundingClientRect();
    const bounds = tooltip.getBoundingClientRect();
    tooltip.style.left = `${Math.max(8, Math.min(anchor.right - bounds.width, window.innerWidth - bounds.width - 8))}px`;
    tooltip.style.top = `${Math.max(8, anchor.bottom + bounds.height + 8 <= window.innerHeight
      ? anchor.bottom + 8 : anchor.top - bounds.height - 8)}px`;
    const description = target.getAttribute("aria-describedby");
    target.setAttribute("aria-describedby", [description, id].filter(Boolean).join(" "));
    return () => {
      if (description) target.setAttribute("aria-describedby", description);
      else target.removeAttribute("aria-describedby");
    };
  }, [id, target]);

  if (!target?.isConnected) return null;
  return createPortal(
    <div ref={tooltipRef} id={id} role="tooltip" popover="manual" className="action-tooltip">
      {target.dataset.shortcutTip}
    </div>, document.body,
  );
}
