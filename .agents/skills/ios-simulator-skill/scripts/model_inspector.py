#!/usr/bin/env python3
"""
Core Data / SwiftData Model Inspector

Parse .xcdatamodeld packages and @Model declarations from project source files.
Zero external dependencies — uses stdlib xml and regex.

Usage:
  python scripts/model_inspector.py --project-path /path/to/project
  python scripts/model_inspector.py --project-path . --verbose
  python scripts/model_inspector.py --project-path . --json
  python scripts/model_inspector.py --project-path . --show-versions
"""

import argparse
import json
import plistlib
import re
import sys
from pathlib import Path
from xml.etree import ElementTree


class ModelInspector:
    """Inspects Core Data and SwiftData models from project source files."""

    def __init__(self, project_path: str):
        """Initialize inspector.

        Args:
            project_path: Path to Xcode project root directory
        """
        self.project_path = Path(project_path).resolve()

    def execute(
        self,
        *,
        core_data_only: bool = False,
        swiftdata_only: bool = False,
        show_versions: bool = False,
    ) -> tuple[bool, dict]:
        """Inspect models and return structured results.

        Args:
            core_data_only: Skip SwiftData scanning
            swiftdata_only: Skip Core Data scanning
            show_versions: Include version history details
        Returns:
            (success, results_dict) tuple
        """
        if not self.project_path.is_dir():
            return False, {"error": f"Directory not found: {self.project_path}"}

        results: dict = {"core_data": [], "swiftdata": []}

        if not swiftdata_only:
            packages = self._find_xcdatamodeld()
            for package in packages:
                parsed = self._parse_xcdatamodeld(package, show_versions=show_versions)
                if parsed:
                    results["core_data"].append(parsed)

        if not core_data_only:
            models = self._find_swiftdata_models()
            results["swiftdata"] = models

        has_results = bool(results["core_data"]) or bool(results["swiftdata"])
        return has_results, results

    # === RAW SOURCE EXTRACTION ===

    def get_raw_source(self, model_name: str) -> tuple[bool, str]:
        """Get raw source for a named model.

        Searches SwiftData @Model classes first, then Core Data XML entities.

        Args:
            model_name: Class or entity name to look up

        Returns:
            (success, raw_source) tuple
        """
        # Search SwiftData files
        swift_files = sorted(self.project_path.rglob("*.swift"))
        skip_dirs = {"DerivedData", "Pods", "Carthage"}

        model_pattern = re.compile(
            r"@Model\s*\n\s*(?:final\s+)?class\s+(\w+)",
            re.MULTILINE,
        )

        for swift_file in swift_files:
            if any(
                part in skip_dirs or part.startswith(".")
                for part in swift_file.relative_to(self.project_path).parts
            ):
                continue

            try:
                content = swift_file.read_text(encoding="utf-8")
            except (OSError, UnicodeDecodeError):
                continue

            for match in model_pattern.finditer(content):
                if match.group(1) == model_name:
                    class_start = match.start()
                    body = self._extract_class_body(content, match.end())
                    if body is None:
                        continue
                    # Find closing brace position
                    brace_start = content.find("{", match.end())
                    depth = 0
                    end = brace_start
                    for i in range(brace_start, len(content)):
                        if content[i] == "{":
                            depth += 1
                        elif content[i] == "}":
                            depth -= 1
                            if depth == 0:
                                end = i + 1
                                break
                    rel_path = swift_file.relative_to(self.project_path)
                    raw = content[class_start:end]
                    return True, f"// {rel_path}\n{raw}"

        # Search Core Data XML
        for package in self._find_xcdatamodeld():
            current_version = self._detect_current_version(package)
            versions = [d for d in package.iterdir() if d.suffix == ".xcdatamodel"]
            target = current_version or (versions[0].name if versions else None)
            if not target:
                continue
            contents_path = package / target / "contents"
            if not contents_path.exists():
                continue
            try:
                tree = ElementTree.parse(contents_path)
            except ElementTree.ParseError:
                continue
            for entity_elem in tree.getroot().findall("entity"):
                if entity_elem.get("name") == model_name:
                    raw_xml = ElementTree.tostring(entity_elem, encoding="unicode")
                    return True, f"<!-- {package.name}/{target}/contents -->\n{raw_xml}"

        return False, f"Model '{model_name}' not found"

    # === CORE DATA PARSING ===

    def _find_xcdatamodeld(self) -> list[Path]:
        """Find all .xcdatamodeld packages in the project."""
        return sorted(self.project_path.rglob("*.xcdatamodeld"))

    def _parse_xcdatamodeld(
        self, package_path: Path, *, show_versions: bool = False
    ) -> dict | None:
        """Parse a .xcdatamodeld package into structured data.

        Args:
            package_path: Path to the .xcdatamodeld directory
            show_versions: Include all version details

        Returns:
            Parsed model data or None on error
        """
        current_version = self._detect_current_version(package_path)
        versions = sorted(
            [d.name for d in package_path.iterdir() if d.suffix == ".xcdatamodel"],
        )

        result: dict = {
            "package": package_path.name,
            "current_version": current_version,
            "version_count": len(versions),
            "entities": [],
        }

        if show_versions:
            result["versions"] = [{"name": v, "is_current": v == current_version} for v in versions]

        # Parse the current version (or first available)
        target_version = current_version or (versions[0] if versions else None)
        if not target_version:
            return result

        contents_path = package_path / target_version / "contents"
        if not contents_path.exists():
            return result

        entities = self._parse_contents_xml(contents_path)
        result["entities"] = entities

        return result

    def _detect_current_version(self, package_path: Path) -> str | None:
        """Read .xccurrentversion plist to find active model version.

        Args:
            package_path: Path to the .xcdatamodeld directory

        Returns:
            Current version name or None
        """
        plist_path = package_path / ".xccurrentversion"
        if not plist_path.exists():
            return None

        try:
            with open(plist_path, "rb") as f:
                plist = plistlib.load(f)
            return plist.get("_XCCurrentVersionName")
        except Exception:
            return None

    def _parse_contents_xml(self, xml_path: Path) -> list[dict]:
        """Parse a Core Data contents XML file.

        Args:
            xml_path: Path to the contents XML file

        Returns:
            List of entity dicts with attributes, relationships, and fetch requests
        """
        try:
            tree = ElementTree.parse(xml_path)
        except ElementTree.ParseError:
            return []

        root = tree.getroot()
        entities = []

        for entity_elem in root.findall("entity"):
            entity: dict = {
                "name": entity_elem.get("name", ""),
                "is_abstract": entity_elem.get("isAbstract") == "YES",
                "parent_entity": entity_elem.get("parentEntity"),
                "represented_class": entity_elem.get("representedClassName"),
                "attributes": [],
                "relationships": [],
                "fetch_requests": [],
            }

            for attr in entity_elem.findall("attribute"):
                entity["attributes"].append(
                    {
                        "name": attr.get("name", ""),
                        "type": attr.get("attributeType", ""),
                        "optional": attr.get("optional") == "YES",
                        "default_value": attr.get("defaultValueString"),
                    }
                )

            for rel in entity_elem.findall("relationship"):
                entity["relationships"].append(
                    {
                        "name": rel.get("name", ""),
                        "destination": rel.get("destinationEntity", ""),
                        "to_many": rel.get("toMany") == "YES",
                        "inverse": rel.get("inverseName"),
                        "optional": rel.get("optional") == "YES",
                    }
                )

            for req in entity_elem.findall("fetchRequest"):
                entity["fetch_requests"].append(
                    {
                        "name": req.get("name", ""),
                        "predicate": req.get("predicateString", ""),
                    }
                )

            # Remove None parent_entity for cleaner output
            if entity["parent_entity"] is None:
                del entity["parent_entity"]

            entities.append(entity)

        return entities

    # === SWIFTDATA EXTRACTION ===

    def _find_swiftdata_models(self) -> list[dict]:
        """Best-effort regex extraction of @Model classes from .swift files.

        Returns:
            List of detected model dicts
        """
        models = []
        swift_files = sorted(self.project_path.rglob("*.swift"))

        # Skip common non-source directories and any dotdirs (e.g. .archived, .build, .git)
        skip_dirs = {"DerivedData", "Pods", "Carthage"}

        for swift_file in swift_files:
            if any(
                part in skip_dirs or part.startswith(".")
                for part in swift_file.relative_to(self.project_path).parts
            ):
                continue

            try:
                content = swift_file.read_text(encoding="utf-8")
            except (OSError, UnicodeDecodeError):
                continue

            file_models = self._extract_models_from_swift(content, swift_file)
            models.extend(file_models)

        return models

    def _extract_models_from_swift(self, content: str, file_path: Path) -> list[dict]:
        """Extract @Model class declarations from Swift source.

        Args:
            content: Swift source file content
            file_path: Path to the source file (for reporting)

        Returns:
            List of model dicts found in this file
        """
        models = []

        # Match @Model decorator followed by class declaration
        model_pattern = re.compile(
            r"@Model\s*\n\s*(?:final\s+)?class\s+(\w+)",
            re.MULTILINE,
        )

        for match in model_pattern.finditer(content):
            class_name = match.group(1)
            class_start = match.end()

            # Find the class body by counting braces
            body = self._extract_class_body(content, class_start)
            if body is None:
                continue

            properties = self._extract_swift_properties(body)
            relationships = self._extract_swift_relationships(body)

            models.append(
                {
                    "class_name": class_name,
                    "file": str(file_path.relative_to(self.project_path)),
                    "properties": properties,
                    "relationships": relationships,
                }
            )

        return models

    def _extract_class_body(self, content: str, start: int) -> str | None:
        """Extract class body by matching braces.

        Args:
            content: Full file content
            start: Position after class name

        Returns:
            Class body string or None if braces don't balance
        """
        brace_start = content.find("{", start)
        if brace_start == -1:
            return None

        depth = 0
        for i in range(brace_start, len(content)):
            if content[i] == "{":
                depth += 1
            elif content[i] == "}":
                depth -= 1
                if depth == 0:
                    return content[brace_start + 1 : i]

        return None

    def _extract_swift_properties(self, body: str) -> list[dict]:
        """Extract stored properties from a Swift class body.

        Args:
            body: Class body content

        Returns:
            List of property dicts
        """
        properties = []
        # Match var/let declarations (skip computed properties with { get })
        prop_pattern = re.compile(
            r"^\s*(?:var|let)\s+(\w+)\s*:\s*([^\n{=]+?)(?:\s*=\s*[^\n]+)?$",
            re.MULTILINE,
        )

        for match in prop_pattern.finditer(body):
            name = match.group(1)
            # Strip trailing inline comments (// ...)
            prop_type = re.sub(r"\s*//.*$", "", match.group(2)).strip()

            # Skip if preceded by @Relationship on current or previous line
            line_start = body.rfind("\n", 0, match.start()) + 1
            prev_line_start = body.rfind("\n", 0, max(0, line_start - 1)) + 1
            preceding = body[prev_line_start : match.start()]
            if "@Relationship" in preceding:
                continue

            properties.append({"name": name, "type": prop_type})

        return properties

    def _extract_swift_relationships(self, body: str) -> list[dict]:
        """Extract @Relationship properties from a Swift class body.

        Args:
            body: Class body content

        Returns:
            List of relationship dicts
        """
        relationships = []
        rel_pattern = re.compile(
            r"@Relationship[^\n]*\n\s*(?:var|let)\s+(\w+)\s*:\s*([^\n{=]+)",
            re.MULTILINE,
        )

        for match in rel_pattern.finditer(body):
            name = match.group(1)
            rel_type = re.sub(r"\s*//.*$", "", match.group(2)).strip()
            to_many = rel_type.startswith("[") or "Array<" in rel_type

            relationships.append(
                {
                    "name": name,
                    "type": rel_type,
                    "to_many": to_many,
                }
            )

        return relationships


# === OUTPUT FORMATTING ===


def format_default(results: dict) -> str:
    """Format results as token-efficient summary.

    Args:
        results: Parsed model data

    Returns:
        Formatted string (3-5 lines)
    """
    lines = []

    for model in results["core_data"]:
        entities = model["entities"]
        attr_count = sum(len(e["attributes"]) for e in entities)
        rel_count = sum(len(e["relationships"]) for e in entities)

        version_info = f"{model['version_count']} version"
        if model["version_count"] != 1:
            version_info += "s"
        if model["current_version"]:
            current = model["current_version"].replace(".xcdatamodel", "")
            version_info += f", current: {current}"

        lines.append(f"Core Data: {model['package']} ({version_info})")
        lines.append(
            f"  {len(entities)} entities, {attr_count} attributes, {rel_count} relationships"
        )

    if results["swiftdata"]:
        count = len(results["swiftdata"])
        names = ", ".join(m["class_name"] for m in results["swiftdata"])
        lines.append(f"SwiftData: {count} @Model class{'es' if count != 1 else ''} ({names})")

    return "\n".join(lines)


def format_verbose(results: dict) -> str:
    """Format results with full details.

    Args:
        results: Parsed model data

    Returns:
        Formatted string with entity/attribute/relationship details
    """
    lines = []

    for model in results["core_data"]:
        lines.append(f"Core Data: {model['package']}")

        if model.get("versions"):
            version_list = []
            for v in model["versions"]:
                name = v["name"].replace(".xcdatamodel", "")
                suffix = " (current)" if v["is_current"] else ""
                version_list.append(f"{name}{suffix}")
            lines.append(f"  Versions: {', '.join(version_list)}")

        if model.get("current_version"):
            current = model["current_version"].replace(".xcdatamodel", "")
            lines.append(f"  Current version: {current}")

        lines.append("")

        for entity in model["entities"]:
            attr_count = len(entity["attributes"])
            rel_count = len(entity["relationships"])
            abstract = " (abstract)" if entity.get("is_abstract") else ""
            parent = f" extends {entity['parent_entity']}" if entity.get("parent_entity") else ""
            lines.append(
                f"  Entity: {entity['name']}{abstract}{parent}"
                f" ({attr_count} attributes, {rel_count} relationships)"
            )

            if entity["attributes"]:
                lines.append("    Attributes:")
                for attr in entity["attributes"]:
                    optional = "optional" if attr["optional"] else "required"
                    default = f", default: {attr['default_value']}" if attr["default_value"] else ""
                    lines.append(f"      - {attr['name']}: {attr['type']} ({optional}{default})")

            if entity["relationships"]:
                lines.append("    Relationships:")
                for rel in entity["relationships"]:
                    cardinality = "toMany" if rel["to_many"] else "toOne"
                    inverse = f", inverse: {rel['inverse']}" if rel["inverse"] else ""
                    lines.append(
                        f"      - {rel['name']}: {rel['destination']} ({cardinality}{inverse})"
                    )

            if entity["fetch_requests"]:
                lines.append("    Fetch Requests:")
                for req in entity["fetch_requests"]:
                    lines.append(f"      - {req['name']}: {req['predicate']}")

            lines.append("")

    if results["swiftdata"]:
        lines.append("SwiftData:")
        for model in results["swiftdata"]:
            prop_count = len(model["properties"])
            rel_count = len(model["relationships"])
            lines.append(
                f"  @Model {model['class_name']} ({prop_count} properties, {rel_count} relationships)"
            )
            lines.append(f"    File: {model['file']}")

            if model["properties"]:
                for prop in model["properties"]:
                    lines.append(f"    - {prop['name']}: {prop['type']}")

            if model["relationships"]:
                for rel in model["relationships"]:
                    cardinality = "toMany" if rel["to_many"] else "toOne"
                    lines.append(f"    @Relationship {rel['name']}: {rel['type']} ({cardinality})")

            lines.append("")

    return "\n".join(lines).rstrip()


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Inspect Core Data and SwiftData models from project files",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python scripts/model_inspector.py --project-path /path/to/project
  python scripts/model_inspector.py --project-path . --verbose
  python scripts/model_inspector.py --project-path . --json
  python scripts/model_inspector.py --project-path . --show-versions
  python scripts/model_inspector.py --project-path . --core-data-only
  python scripts/model_inspector.py --project-path . --raw TrainingSession
        """,
    )

    inspection_group = parser.add_argument_group("Inspection Options")
    inspection_group.add_argument(
        "--project-path",
        default=".",
        help="Path to Xcode project root (default: current directory)",
    )
    inspection_group.add_argument(
        "--core-data-only",
        action="store_true",
        help="Only inspect Core Data .xcdatamodeld packages",
    )
    inspection_group.add_argument(
        "--swiftdata-only",
        action="store_true",
        help="Only inspect SwiftData @Model classes",
    )
    inspection_group.add_argument(
        "--show-versions",
        action="store_true",
        help="List all model versions with current version highlighted",
    )
    inspection_group.add_argument(
        "--raw",
        metavar="MODEL_NAME",
        help="Dump raw source for a specific model (Swift class or Core Data entity)",
    )

    output_group = parser.add_argument_group("Output Options")
    output_group.add_argument("--json", action="store_true", help="Output as JSON")
    output_group.add_argument("--verbose", action="store_true", help="Show full details")

    args = parser.parse_args()

    inspector = ModelInspector(project_path=args.project_path)

    if args.raw:
        success, raw = inspector.get_raw_source(args.raw)
        if success:
            print(raw)
        else:
            print(f"Error: {raw}", file=sys.stderr)
            sys.exit(1)
        return

    success, results = inspector.execute(
        core_data_only=args.core_data_only,
        swiftdata_only=args.swiftdata_only,
        show_versions=args.show_versions,
    )

    if not success:
        if "error" in results:
            print(f"Error: {results['error']}", file=sys.stderr)
        else:
            print("No Core Data or SwiftData models found", file=sys.stderr)
        sys.exit(1)

    if args.json:
        print(json.dumps(results, indent=2, default=str))
    elif args.verbose or args.show_versions:
        print(format_verbose(results))
    else:
        print(format_default(results))


if __name__ == "__main__":
    main()
