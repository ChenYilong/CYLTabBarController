import { useEffect, useId, useRef, useState } from "react";
import { Icon } from "./Icon";

export function HostedFileName({ name, editable, onRename }: {
  name: string;
  editable: boolean;
  onRename: (name: string) => Promise<void>;
}) {
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState(name);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const inputRef = useRef<HTMLInputElement>(null);
  const triggerRef = useRef<HTMLButtonElement>(null);
  const savingRef = useRef(false);
  const errorId = useId();

  useEffect(() => {
    if (editing) {
      inputRef.current?.focus();
      inputRef.current?.select();
    }
  }, [editing]);

  const finish = () => {
    setEditing(false);
    requestAnimationFrame(() => triggerRef.current?.focus());
  };

  const save = async () => {
    if (savingRef.current) return;
    const nextName = draft.trim();
    if (!nextName || [...nextName].length > 120) {
      setError("请输入 1–120 个字符的名称");
      inputRef.current?.focus();
      return;
    }
    savingRef.current = true;
    setSaving(true);
    setError("");
    try {
      await onRename(nextName);
      finish();
    } catch (renameError) {
      setError(renameError instanceof Error ? renameError.message : "重命名失败，请重试");
    } finally {
      savingRef.current = false;
      setSaving(false);
    }
  };

  if (editing) return (
    <div className="file-name-editor">
      <form
        className="file-name-form"
        aria-label="重命名文件"
        onSubmit={(event) => { event.preventDefault(); void save(); }}
        onKeyDown={(event) => {
          event.stopPropagation();
          if (event.nativeEvent.isComposing) {
            if (event.key === "Enter") event.preventDefault();
            return;
          }
          if (event.key === "Escape") {
            event.preventDefault();
            if (!savingRef.current) finish();
          }
        }}
      >
        <input
          ref={inputRef}
          aria-label="文件名称"
          aria-invalid={Boolean(error)}
          aria-describedby={error ? errorId : undefined}
          value={draft}
          disabled={saving}
          onChange={(event) => { setDraft(event.target.value); setError(""); }}
        />
        <button type="submit" disabled={saving} aria-label="保存文件名称" title="保存 (Enter)">
          <Icon name="check" size={16} />
        </button>
        <button type="button" disabled={saving} onClick={finish} aria-label="取消重命名" title="取消 (Esc)">
          <Icon name="x" size={16} />
        </button>
      </form>
      {saving && <div className="file-name-status" role="status">正在保存…</div>}
      {error && <div id={errorId} className="file-name-error" role="alert">{error}</div>}
    </div>
  );

  return (
    <div className="file-name-row">
      <h1 title={name}>{name}</h1>
      {editable && <button
        ref={triggerRef}
        className="file-name-edit press-feedback"
        type="button"
        aria-label="重命名文件"
        title="重命名文件"
        onClick={() => { setDraft(name); setError(""); setEditing(true); }}
      >
        <Icon name="pencil-simple" size={15} />
      </button>}
    </div>
  );
}
