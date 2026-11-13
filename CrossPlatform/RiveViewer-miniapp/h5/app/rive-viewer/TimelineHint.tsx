import { lazy, Suspense, useEffect, useState } from "react";

const AnimatedCalligraph = lazy(() => import("calligraph").then(({ Calligraph }) => ({
  default: Calligraph,
})));

const TIMELINE_HINTS = [
  "写下评论或备注",
  "点击时间轴，可以直接引用到评论",
  "一条评论可以引用多个时间轴",
  "发现动作问题时，顺手留下评论",
];

function useReducedMotionPreference() {
  const [reducedMotion, setReducedMotion] = useState(false);

  useEffect(() => {
    const query = window.matchMedia("(prefers-reduced-motion: reduce)");
    const update = () => setReducedMotion(query.matches);
    update();
    query.addEventListener("change", update);
    return () => query.removeEventListener("change", update);
  }, []);

  return reducedMotion;
}

export function TimelineHint() {
  const reducedMotion = useReducedMotionPreference();
  const [hintIndex, setHintIndex] = useState(() => Math.floor(Math.random() * TIMELINE_HINTS.length));
  const hint = TIMELINE_HINTS[hintIndex];

  useEffect(() => {
    if (reducedMotion) return undefined;
    const intervalId = window.setInterval(() => {
      setHintIndex((current) => (current + 1) % TIMELINE_HINTS.length);
    }, 5200);
    return () => window.clearInterval(intervalId);
  }, [reducedMotion]);

  return (
    <span className="comment-editor-placeholder" aria-hidden="true">
      {reducedMotion ? (
        <span className="comment-editor-placeholder-text">{hint}</span>
      ) : (
        <Suspense fallback={<span className="comment-editor-placeholder-text">{hint}</span>}>
          <AnimatedCalligraph
            className="comment-editor-placeholder-text"
            animation="smooth"
            autoSize={false}
            drift={{ x: 5, y: 3 }}
            initial
            stagger={0.01}
          >
            {hint}
          </AnimatedCalligraph>
        </Suspense>
      )}
    </span>
  );
}
