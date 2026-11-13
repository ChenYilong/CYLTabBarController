export type TimelineGroupItem = {
  name: string;
  label: string;
};

export type TimelineLayout = "expanded" | "organized";

export function getDefaultTimelineLayout(
  animationCount: number,
  canOrganize = true,
): TimelineLayout {
  return animationCount > 10 && canOrganize ? "organized" : "expanded";
}

export type TimelineSection =
  | { type: "group"; prefix: string; items: TimelineGroupItem[] }
  | { type: "timeline"; item: TimelineGroupItem };

function splitTimelineName(name: string): { prefix: string; suffix: string } | null {
  const separatorIndex = name.indexOf("_");
  if (separatorIndex <= 0 || separatorIndex >= name.length - 1) return null;
  return {
    prefix: name.slice(0, separatorIndex),
    suffix: name.slice(separatorIndex + 1),
  };
}

export function organizeTimelines(names: string[]): TimelineSection[] {
  const parsed = names.map((name) => ({ name, parts: splitTimelineName(name) }));
  const prefixCounts = new Map<string, number>();
  parsed.forEach(({ parts }) => {
    if (parts) prefixCounts.set(parts.prefix, (prefixCounts.get(parts.prefix) || 0) + 1);
  });

  const emittedPrefixes = new Set<string>();
  const standaloneSections: TimelineSection[] = [];
  const groupedSections: TimelineSection[] = [];
  parsed.forEach(({ name, parts }) => {
    if (!parts || (prefixCounts.get(parts.prefix) || 0) < 2) {
      standaloneSections.push({ type: "timeline", item: { name, label: name } });
      return;
    }
    if (emittedPrefixes.has(parts.prefix)) return;
    emittedPrefixes.add(parts.prefix);
    groupedSections.push({
      type: "group",
      prefix: parts.prefix,
      items: parsed.flatMap(({ name: groupedName, parts: groupedParts }) => (
        groupedParts?.prefix === parts.prefix
          ? [{ name: groupedName, label: groupedParts.suffix }]
          : []
      )),
    });
  });
  return [...standaloneSections, ...groupedSections];
}

export function hasOrganizableTimelineGroups(sections: TimelineSection[]): boolean {
  return sections.some((section) => section.type === "group");
}
