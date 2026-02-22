import os, json, glob, sys, subprocess, xml.etree.ElementTree as ET, re, time, difflib
from pathlib import Path
from openai import OpenAI
from typing import Dict, List, Optional, Any

REPO_ROOT = Path(__file__).resolve().parents[1]
PROMPTS_DIR = REPO_ROOT / "prompts"
TASKS_DIR = REPO_ROOT / "agent" / "tasks"
QUEUED_DIR = TASKS_DIR / "queued"
PROCESSED_DIR = TASKS_DIR / "processed"
IOS_DIR = REPO_ROOT / "ios"

ORCH = (PROMPTS_DIR / "orchestrator.md").read_text()
IOS  = (PROMPTS_DIR / "ios_dev.md").read_text()
DESIGN_REVIEW_PROMPT = (PROMPTS_DIR / "design_review.md").read_text()

DEFAULT_MODEL = os.environ.get("AGENT_LLM_MODEL", "gpt-4o")

# Retry budgets
MAX_BUILD_RETRIES = 4              # Build error fix attempts (up from 2)
MAX_DESIGN_RETRIES = 2             # Design review improvement iterations
MAX_POST_DESIGN_BUILD_RETRIES = 2  # Build retries after design fixes


# ---------------------------------------------------------------------------
# OpenAI API retry wrapper
# ---------------------------------------------------------------------------

def _call_openai_with_retry(client: OpenAI, max_api_retries: int = 3, **kwargs) -> dict:
    """Wrapper around OpenAI chat completions with exponential backoff.

    Handles transient errors (rate limits, timeouts) and JSON decode failures.
    Returns the parsed JSON dict from the response.
    """
    last_error = None
    for attempt in range(max_api_retries):
        try:
            resp = client.chat.completions.create(**kwargs)
            content = resp.choices[0].message.content
            return json.loads(content)
        except json.JSONDecodeError as e:
            print(f"  LLM returned invalid JSON (attempt {attempt + 1}/{max_api_retries}): {e}")
            last_error = e
            if attempt == max_api_retries - 1:
                raise
        except Exception as e:
            err_str = str(e).lower()
            if "rate_limit" in err_str or "timeout" in err_str or "connection" in err_str:
                wait_time = 2 ** attempt * 5  # 5s, 10s, 20s
                print(f"  API error (attempt {attempt + 1}/{max_api_retries}): {e}. Retrying in {wait_time}s...")
                time.sleep(wait_time)
                last_error = e
            else:
                raise
    raise RuntimeError(f"OpenAI API call failed after {max_api_retries} retries: {last_error}")


# ---------------------------------------------------------------------------
# Xcode project analysis
# ---------------------------------------------------------------------------

class XcodeProjectAnalyzer:
    """Analyzes and manipulates Xcode project files"""

    def __init__(self, project_path: Path):
        self.project_path = project_path
        self.pbxproj_path = project_path / "project.pbxproj"

    def get_project_info(self) -> Dict[str, Any]:
        """Extract key project information"""
        if not self.pbxproj_path.exists():
            return {"error": "No Xcode project found"}

        try:
            content = self.pbxproj_path.read_text()

            # Extract basic project info using regex
            bundle_id_match = re.search(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*([^;]+);', content)
            target_match = re.search(r'productName\s*=\s*([^;]+);', content)

            return {
                "bundle_identifier": bundle_id_match.group(1).strip('"') if bundle_id_match else "unknown",
                "target_name": target_match.group(1).strip('"') if target_match else "unknown",
                "swift_files": self._find_swift_files(),
                "storyboards": self._find_storyboards(),
                "has_swiftui": self._has_swiftui_imports(),
                "dependencies": self._get_dependencies()
            }
        except Exception as e:
            return {"error": f"Failed to parse project: {str(e)}"}

    def _find_swift_files(self) -> List[str]:
        """Find all Swift files in the project"""
        swift_files = []
        if IOS_DIR.exists():
            for swift_file in IOS_DIR.rglob("*.swift"):
                swift_files.append(str(swift_file.relative_to(REPO_ROOT)))
        return swift_files

    def _find_storyboards(self) -> List[str]:
        """Find all Storyboard files"""
        storyboards = []
        if IOS_DIR.exists():
            for sb_file in IOS_DIR.rglob("*.storyboard"):
                storyboards.append(str(sb_file.relative_to(REPO_ROOT)))
        return storyboards

    def _has_swiftui_imports(self) -> bool:
        """Check if project uses SwiftUI"""
        for swift_file in IOS_DIR.rglob("*.swift") if IOS_DIR.exists() else []:
            try:
                content = swift_file.read_text()
                if "import SwiftUI" in content:
                    return True
            except:
                continue
        return False

    def _get_dependencies(self) -> Dict[str, List[str]]:
        """Get project dependencies"""
        deps = {"cocoapods": [], "spm": []}

        # Check for CocoaPods
        podfile = REPO_ROOT / "Podfile"
        if podfile.exists():
            try:
                content = podfile.read_text()
                pod_matches = re.findall(r"pod\s+['\"]([^'\"]+)['\"]", content)
                deps["cocoapods"] = pod_matches
            except:
                pass

        # Check for Swift Package Manager
        package_swift = REPO_ROOT / "Package.swift"
        if package_swift.exists():
            try:
                content = package_swift.read_text()
                url_matches = re.findall(r'url:\s*"([^"]+)"', content)
                deps["spm"] = url_matches
            except:
                pass

        return deps

class iOSCodeGenerator:
    """Generates iOS-specific code with best practices"""

    @staticmethod
    def generate_swiftui_view(name: str, properties: Dict[str, Any]) -> str:
        """Generate a SwiftUI view template"""
        view_name = name.replace(" ", "").replace("-", "")

        template = f"""import SwiftUI

struct {view_name}: View {{
    var body: some View {{
        VStack {{
            Text("{name}")
                .font(.title)
                .fontWeight(.bold)

            // TODO: Implement view content
        }}
        .padding()
        .navigationTitle("{name}")
    }}
}}

struct {view_name}_Previews: PreviewProvider {{
    static var previews: some View {{
        {view_name}()
    }}
}}
"""
        return template

    @staticmethod
    def generate_view_model(name: str, properties: Dict[str, Any]) -> str:
        """Generate a ViewModel for MVVM pattern"""
        class_name = f"{name.replace(' ', '').replace('-', '')}ViewModel"

        template = f"""import Foundation
import Combine

class {class_name}: ObservableObject {{
    // MARK: - Published Properties

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init() {{
        setupBindings()
    }}

    // MARK: - Private Methods
    private func setupBindings() {{
        // TODO: Setup data bindings
    }}

    // MARK: - Public Methods

}}
"""
        return template

    @staticmethod
    def generate_model(name: str, properties: Dict[str, Any]) -> str:
        """Generate a Swift model/struct"""
        struct_name = name.replace(" ", "").replace("-", "")

        # Generate properties from the properties dict
        props = []
        for prop_name, prop_type in properties.get("properties", {}).items():
            props.append(f"    let {prop_name}: {prop_type}")

        properties_str = "\n".join(props) if props else "    let id = UUID()"

        template = f"""import Foundation

struct {struct_name}: Identifiable, Codable {{
{properties_str}
}}
"""
        return template

def analyze_ios_project() -> Dict[str, Any]:
    """Analyze the iOS project and return context"""
    context = {"has_ios_project": False}

    # Find Xcode project
    xcode_projects = list(IOS_DIR.rglob("*.xcodeproj")) if IOS_DIR.exists() else []

    if xcode_projects:
        context["has_ios_project"] = True
        analyzer = XcodeProjectAnalyzer(xcode_projects[0])
        context.update(analyzer.get_project_info())
        context["project_path"] = str(xcode_projects[0].relative_to(REPO_ROOT))

    # Get existing iOS file structure
    if IOS_DIR.exists():
        context["ios_structure"] = get_directory_structure(IOS_DIR)

    return context

def get_directory_structure(path: Path, max_depth: int = 3, current_depth: int = 0) -> Dict:
    """Get directory structure for context"""
    if current_depth > max_depth:
        return {}

    structure = {}
    try:
        for item in sorted(path.iterdir()):
            if item.name.startswith('.'):
                continue
            if item.is_dir():
                structure[item.name + "/"] = get_directory_structure(item, max_depth, current_depth + 1)
            else:
                structure[item.name] = "file"
    except PermissionError:
        pass

    return structure

def load_task(task_path: Path) -> dict:
    return json.loads(task_path.read_text())


# ---------------------------------------------------------------------------
# LLM calling functions
# ---------------------------------------------------------------------------

def _get_client() -> OpenAI:
    """Get an OpenAI client, raising if no API key is set."""
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        raise RuntimeError("OPENAI_API_KEY not set")
    return OpenAI(api_key=api_key)


def _build_enriched_context(task: dict, ios_context: dict) -> dict:
    """Build enriched iOS context with file contents for LLM calls."""
    ios_context_enriched = dict(ios_context)

    # Read ContentView.swift for navigation integration
    content_view_path = REPO_ROOT / "ios" / "PT-Helper" / "PT-Helper" / "ContentView.swift"
    if content_view_path.exists():
        ios_context_enriched["content_view_swift"] = content_view_path.read_text()
    else:
        ios_context_enriched["content_view_swift"] = ""

    # Read existing files for "update" deliverables
    existing_file_contents = {}
    for deliverable in task.get("deliverables", []):
        if (deliverable.get("type") or "").lower() == "update":
            d_path = REPO_ROOT / deliverable["path"]
            if d_path.exists():
                existing_file_contents[deliverable["path"]] = d_path.read_text()
    if existing_file_contents:
        ios_context_enriched["existing_file_contents"] = existing_file_contents

    # Read any extra context files specified in the task
    context_files_contents = {}
    for cf_path in task.get("context_files", []):
        full_path = REPO_ROOT / cf_path
        if full_path.exists():
            context_files_contents[cf_path] = full_path.read_text()
    if context_files_contents:
        ios_context_enriched["context_files_contents"] = context_files_contents

    return ios_context_enriched


def call_llm(task: dict, ios_context: dict, model_name: str = DEFAULT_MODEL) -> dict:
    """Initial code generation call to LLM."""
    client = _get_client()
    ios_context_enriched = _build_enriched_context(task, ios_context)

    system_prompt = ORCH + "\n\n" + IOS + f"\n\n## iOS Project Context\n{json.dumps(ios_context_enriched, indent=2)}"

    user_prompt = json.dumps({
        "task": task,
        "ios_context": ios_context_enriched
    }, indent=2)

    return _call_openai_with_retry(
        client,
        model=model_name,
        temperature=0.2,
        response_format={"type": "json_object"},
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ],
    )


def _extract_file_path_from_error(error_line: str) -> Optional[str]:
    """Extract a relative file path from an Xcode error line.

    Xcode errors look like:
        /Users/name/project/ios/PT-Helper/PT-Helper/File.swift:12:5: error: ...
    Returns the path relative to REPO_ROOT, or None.
    """
    match = re.match(r'(/[^:]+\.swift):\d+:\d+:', error_line)
    if match:
        abs_path = match.group(1)
        try:
            return str(Path(abs_path).relative_to(REPO_ROOT))
        except ValueError:
            pass
    return None


def call_llm_fix(task: dict, ios_context: dict, previous_result: dict,
                  errors: list, model_name: str = DEFAULT_MODEL) -> dict:
    """Ask LLM to fix compile errors from a previous attempt.

    Now reads the contents of pre-existing files referenced in errors and
    instructs the LLM to use ``action: "patch"`` for surgical edits on those
    files instead of rewriting them from scratch.
    """
    client = _get_client()
    system_prompt = ORCH + "\n\n" + IOS + f"\n\n## iOS Project Context\n{json.dumps(ios_context, indent=2)}"

    # Files the agent created/updated in this task
    agent_file_paths = set()
    for ch in previous_result.get("changes", []):
        agent_file_paths.add(ch["path"])

    # Read the current contents of external files referenced in errors
    error_file_contents = {}
    for err_line in errors:
        file_path = _extract_file_path_from_error(err_line)
        if file_path and file_path not in agent_file_paths and file_path not in error_file_contents:
            full_path = REPO_ROOT / file_path
            if full_path.exists():
                error_file_contents[file_path] = full_path.read_text(encoding="utf-8")

    fix_prompt = json.dumps({
        "instruction": (
            "The code you previously generated has compile errors. Fix them and return the corrected changes JSON.\n"
            "IMPORTANT RULES FOR FIXES:\n"
            "- For files YOU created in this task (listed in previous_changes), use action 'create' or 'update' with FULL file contents.\n"
            "- For PRE-EXISTING files you did NOT create (listed in error_file_contents), use action 'patch' with targeted find-and-replace edits.\n"
            "- NEVER rewrite a pre-existing file from scratch. Use 'patch' to make the SMALLEST change that fixes the error.\n"
            "- Each patch has 'find' (exact text currently in the file) and 'replace' (the corrected text).\n"
            "- Include 2-3 surrounding lines in 'find' to ensure the match is unique."
        ),
        "previous_changes": previous_result.get("changes", []),
        "error_file_contents": error_file_contents,
        "compile_errors": errors,
        "task": task
    }, indent=2)

    return _call_openai_with_retry(
        client,
        model=model_name,
        temperature=0.2,
        response_format={"type": "json_object"},
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": fix_prompt}
        ],
    )


def design_review(task: dict, ios_context: dict, changes: list,
                   model_name: str = DEFAULT_MODEL) -> dict:
    """Evaluate the design quality of generated SwiftUI views.

    Returns a dict with: passes (bool), score (int 1-10), issues (list), summary (str).
    """
    client = _get_client()

    # Read the actual written file contents from disk (post-enhance_swift_code)
    file_contents = {}
    for ch in changes:
        file_path = REPO_ROOT / ch["path"]
        if file_path.exists() and file_path.suffix == ".swift":
            file_contents[ch["path"]] = file_path.read_text()

    if not file_contents:
        return {"passes": True, "score": 7, "issues": [], "summary": "No Swift view files to review."}

    user_prompt = json.dumps({
        "instruction": "Review the following SwiftUI files for design quality. Return your assessment as JSON.",
        "task_requirements": task.get("requirements", []),
        "task_description": task.get("description", ""),
        "files": file_contents
    }, indent=2)

    return _call_openai_with_retry(
        client,
        model=model_name,
        temperature=0.2,
        response_format={"type": "json_object"},
        messages=[
            {"role": "system", "content": DESIGN_REVIEW_PROMPT},
            {"role": "user", "content": user_prompt}
        ],
    )


def call_llm_design_fix(task: dict, ios_context: dict, previous_result: dict,
                         design_feedback: dict, model_name: str = DEFAULT_MODEL) -> dict:
    """Ask LLM to improve design quality based on review feedback.

    Returns the same JSON schema as call_llm (title, summary, changes).
    Uses slightly higher temperature (0.4) for more creative design.
    """
    client = _get_client()

    # Read current file contents from disk so the LLM sees post-enhancement code
    current_file_contents = {}
    for ch in previous_result.get("changes", []):
        file_path = REPO_ROOT / ch["path"]
        if file_path.exists() and file_path.suffix == ".swift":
            current_file_contents[ch["path"]] = file_path.read_text()

    ios_context_enriched = dict(ios_context)
    ios_context_enriched["current_file_contents"] = current_file_contents

    system_prompt = (
        ORCH + "\n\n" + IOS
        + f"\n\n## iOS Project Context\n{json.dumps(ios_context_enriched, indent=2)}"
    )

    # Build list of files the agent created in this task
    agent_created_files = [ch["path"] for ch in previous_result.get("changes", [])]

    fix_prompt = json.dumps({
        "instruction": (
            "The code compiles successfully but has design quality issues. "
            "Improve the visual design of the SwiftUI views based on the feedback below.\n"
            "IMPORTANT RULES:\n"
            "- For files YOU created in this task (listed in agent_created_files), use action 'update' with FULL file contents.\n"
            "- For PRE-EXISTING files you did NOT create, use action 'patch' with targeted find-and-replace edits.\n"
            "- NEVER rewrite a pre-existing file from scratch. Use 'patch' to make the SMALLEST change needed.\n"
            "- Each patch has 'find' (exact text currently in the file) and 'replace' (the corrected text).\n"
            "- Include 2-3 surrounding lines in 'find' to ensure the match is unique.\n"
            "- The code MUST still compile after your changes."
        ),
        "agent_created_files": agent_created_files,
        "design_review_feedback": design_feedback,
        "previous_changes": previous_result.get("changes", []),
        "task": task
    }, indent=2)

    return _call_openai_with_retry(
        client,
        model=model_name,
        temperature=0.4,
        response_format={"type": "json_object"},
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": fix_prompt}
        ],
    )


# ---------------------------------------------------------------------------
# File writing and code enhancement
# ---------------------------------------------------------------------------

def write_changes(changes: list, ios_context: dict):
    """Enhanced write_changes with iOS-specific handling and patch support."""
    for ch in changes:
        path = REPO_ROOT / ch["path"]
        action = ch["action"]

        if action == "delete":
            if path.exists():
                path.unlink()
            continue

        # ── Patch action: surgical find-and-replace ──────────────
        if action == "patch":
            patches = ch.get("patches", [])
            if not patches:
                print(f"  Warning: patch action for {ch['path']} has no patches")
                continue
            success, errors = apply_patches(path, patches)
            if not success:
                for err in errors:
                    print(f"  Patch error: {err}")
                # Fallback: if full content is also provided, use it
                if ch.get("content"):
                    print(f"  Falling back to full file replacement for {ch['path']}")
                    content = ch["content"]
                    if path.suffix == ".swift":
                        content = enhance_swift_code(content, ios_context)
                    path.write_text(content, encoding="utf-8")
            else:
                # Re-run enhance_swift_code on the patched file
                if path.suffix == ".swift":
                    patched = path.read_text(encoding="utf-8")
                    enhanced = enhance_swift_code(patched, ios_context)
                    if enhanced != patched:
                        path.write_text(enhanced, encoding="utf-8")
            continue

        # ── Create / Update: full file replacement (unchanged) ───
        path.parent.mkdir(parents=True, exist_ok=True)

        content = ch.get("content", "")
        if path.suffix == ".swift":
            content = enhance_swift_code(content, ios_context)
        elif path.suffix == ".storyboard":
            content = validate_storyboard_content(content)
        elif path.name == "Info.plist":
            content = validate_plist_content(content)

        path.write_text(content, encoding="utf-8")

def enhance_swift_code(content: str, ios_context: dict) -> str:
    """Ensure Swift code has necessary imports without duplication."""
    lines = content.split('\n')

    has_foundation = any("import Foundation" in line for line in lines)
    has_swiftui = any("import SwiftUI" in line for line in lines)
    has_types = "class " in content or "struct " in content

    prepend = []

    if not has_foundation and has_types:
        prepend.append("import Foundation")

    if not has_swiftui and ios_context.get("has_swiftui", False):
        swiftui_markers = ["View", "StateObject", "State", "ObservedObject",
                           "EnvironmentObject", "NavigationView", "VStack", "HStack",
                           "Button", "Text(", "Slider", "NavigationLink", "TabView"]
        if any(marker in content for marker in swiftui_markers):
            prepend.append("import SwiftUI")

    if prepend:
        return '\n'.join(prepend) + '\n\n' + content
    return content


# ---------------------------------------------------------------------------
# Patch helpers — surgical find-and-replace edits for existing files
# ---------------------------------------------------------------------------

def _normalize_whitespace(text: str) -> str:
    """Normalize whitespace for fuzzy matching: strip trailing per line."""
    lines = text.split('\n')
    return '\n'.join(line.rstrip() for line in lines)


def _replace_by_normalized_match(content: str, find_str: str, replace_str: str) -> Optional[str]:
    """Replace using line-by-line stripped comparison.

    Returns the new content if a match was found, else None.
    """
    content_lines = content.split('\n')
    find_lines = find_str.rstrip('\n').split('\n')
    n = len(find_lines)

    for i in range(len(content_lines) - n + 1):
        window = content_lines[i:i + n]
        if all(a.strip() == b.strip() for a, b in zip(window, find_lines)):
            replace_lines = replace_str.rstrip('\n').split('\n')
            new_lines = content_lines[:i] + replace_lines + content_lines[i + n:]
            return '\n'.join(new_lines)
    return None


def _fuzzy_replace(content: str, find_str: str, replace_str: str,
                   threshold: float = 0.85) -> Optional[str]:
    """Fuzzy find-and-replace using SequenceMatcher on line windows.

    Slides a window of the same line count as *find_str* across *content*
    and picks the best match above *threshold*.
    """
    content_lines = content.split('\n')
    find_lines = find_str.rstrip('\n').split('\n')
    n = len(find_lines)

    if n > len(content_lines):
        return None

    best_ratio = 0.0
    best_idx = -1

    for i in range(len(content_lines) - n + 1):
        window = '\n'.join(content_lines[i:i + n])
        ratio = difflib.SequenceMatcher(None, window, find_str.rstrip('\n')).ratio()
        if ratio > best_ratio:
            best_ratio = ratio
            best_idx = i

    if best_ratio >= threshold and best_idx >= 0:
        replace_lines = replace_str.rstrip('\n').split('\n')
        new_lines = content_lines[:best_idx] + replace_lines + content_lines[best_idx + n:]
        return '\n'.join(new_lines)

    return None


def apply_patches(file_path: Path, patches: list) -> tuple:
    """Apply find-and-replace patches to an existing file.

    Returns *(success, errors)* where *success* is ``True`` only when every
    patch was applied.  The file is written back to disk only on full success.
    """
    if not file_path.exists():
        return False, [f"File not found: {file_path}"]

    content = file_path.read_text(encoding="utf-8")
    errors: list[str] = []

    for i, patch in enumerate(patches):
        find_str = patch.get("find", "")
        replace_str = patch.get("replace", "")

        if not find_str:
            errors.append(f"Patch {i}: empty 'find' string")
            continue

        # Attempt 1: exact match
        if find_str in content:
            content = content.replace(find_str, replace_str, 1)
            continue

        # Attempt 2: whitespace-normalized match
        result = _replace_by_normalized_match(content, find_str, replace_str)
        if result is not None:
            content = result
            continue

        # Attempt 3: fuzzy match (0.85 threshold)
        result = _fuzzy_replace(content, find_str, replace_str, threshold=0.85)
        if result is not None:
            content = result
            continue

        errors.append(f"Patch {i}: could not find target string in {file_path.name}")

    if not errors:
        file_path.write_text(content, encoding="utf-8")

    return len(errors) == 0, errors


def validate_storyboard_content(content: str) -> str:
    """Validate and enhance storyboard XML content"""
    try:
        # Basic XML validation
        ET.fromstring(content)
        return content
    except ET.ParseError:
        # Return a basic storyboard template if invalid
        return '''<?xml version="1.0" encoding="UTF-8"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="21701" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" useTraitCollections="YES" useSafeAreas="YES" colorMatched="YES">
    <device id="retina6_12" orientation="portrait" appearance="light"/>
    <dependencies>
        <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="21678"/>
        <capability name="Safe area layout guides" minToolsVersion="9.0"/>
        <capability name="documents saved in the Xcode 8 format" minToolsVersion="8.0"/>
    </dependencies>
    <scenes/>
</document>'''

def validate_plist_content(content: str) -> str:
    """Validate Info.plist content"""
    try:
        # Basic plist validation - check if it's valid XML
        ET.fromstring(content)
        return content
    except ET.ParseError:
        # Return basic plist template
        return '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
</dict>
</plist>'''

def synthesize_ios_content(path: str, ios_context: dict, task: dict) -> str:
    """Enhanced content synthesis for iOS files"""
    path_obj = Path(path)

    if path.endswith(".swift"):
        # Try to determine what type of Swift file to create based on path and task
        if "View" in path or "views" in path.lower():
            return iOSCodeGenerator.generate_swiftui_view(
                path_obj.stem,
                task.get("properties", {})
            )
        elif "ViewModel" in path or "viewmodel" in path.lower():
            return iOSCodeGenerator.generate_view_model(
                path_obj.stem.replace("ViewModel", ""),
                task.get("properties", {})
            )
        elif "Model" in path or "models" in path.lower():
            return iOSCodeGenerator.generate_model(
                path_obj.stem,
                task.get("properties", {})
            )
        else:
            # Generic Swift file
            fname = path_obj.stem
            class_name = fname.replace('-', '_').replace(' ', '_')
            return f"""import Foundation

class {class_name} {{
    // MARK: - Properties

    // MARK: - Initialization
    init() {{
        // TODO: Initialize {class_name}
    }}

    // MARK: - Methods

}}
"""

    elif path.endswith(".storyboard"):
        return validate_storyboard_content("")

    elif path.endswith(".md"):
        return f"# {path_obj.stem}\n\nThis iOS component was generated by the agent.\n\n## Usage\n\nTODO: Add usage instructions.\n"

    elif path.name == "Info.plist":
        return validate_plist_content("")

    # Default fallback
    return f"// {path_obj.name} generated by iOS agent\n// TODO: Implement functionality\n"


# ---------------------------------------------------------------------------
# Xcode build check
# ---------------------------------------------------------------------------

def _ensure_xcode_selected() -> Optional[str]:
    """Ensure xcode-select points to a full Xcode installation. Returns error string or None."""
    try:
        check = subprocess.run(
            ["xcodebuild", "-version"], capture_output=True, text=True, timeout=10
        )
        if check.returncode == 0:
            return None  # Already working

        # Try to auto-fix by selecting Xcode.app
        xcode_paths = [
            "/Applications/Xcode.app/Contents/Developer",
            "/Applications/Xcode_15.4.app/Contents/Developer",
            "/Applications/Xcode_15.app/Contents/Developer",
        ]
        for path in xcode_paths:
            if Path(path).exists():
                fix = subprocess.run(
                    ["sudo", "xcode-select", "-s", path],
                    capture_output=True, text=True, timeout=10
                )
                if fix.returncode == 0:
                    print(f"Auto-selected Xcode at: {path}")
                    return None
        return "xcodebuild requires full Xcode, not just Command Line Tools. Run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    except Exception as e:
        return f"Failed to check Xcode: {str(e)}"


def _parse_scheme(proc_result) -> Optional[str]:
    """Parse the first scheme from xcodebuild -list output.

    The output can contain SPM resolution, Targets, Build Configurations,
    and Schemes sections in varying order. We scan for 'Schemes:' and grab
    the first non-empty line after it.
    """
    if proc_result.returncode != 0:
        return None
    lines = proc_result.stdout.split('\n')
    in_schemes = False
    for line in lines:
        stripped = line.strip()
        if stripped == "Schemes:":
            in_schemes = True
            continue
        if in_schemes:
            if stripped == "" or stripped.endswith(":"):
                break  # End of schemes section
            return stripped  # First scheme found
    return None


def run_ios_build_check() -> Dict[str, Any]:
    """Run actual Xcode build to validate generated code compiles."""
    result = {"can_build": False, "errors": []}

    # Ensure xcode-select points to full Xcode
    xcode_err = _ensure_xcode_selected()
    if xcode_err:
        result["errors"].append(xcode_err)
        return result

    try:
        xcode_projects = list(IOS_DIR.rglob("*.xcodeproj")) if IOS_DIR.exists() else []
        if not xcode_projects:
            result["errors"].append("No Xcode project found")
            return result

        project_path = str(xcode_projects[0])

        # Check for workspace (SPM projects often need -workspace)
        workspace_path = None
        workspace_dir = Path(project_path) / "project.xcworkspace"
        standalone_workspaces = list(Path(project_path).parent.glob("*.xcworkspace"))
        if standalone_workspaces:
            workspace_path = str(standalone_workspaces[0])

        # Discover the scheme — try workspace first, then project
        if workspace_path:
            list_cmd = ["xcodebuild", "-list", "-workspace", workspace_path]
        else:
            list_cmd = ["xcodebuild", "-list", "-project", project_path]
        list_proc = subprocess.run(list_cmd, capture_output=True, text=True, timeout=30)

        scheme = _parse_scheme(list_proc)

        # Fallback: try -project if workspace didn't yield a scheme
        if not scheme and workspace_path:
            list_cmd = ["xcodebuild", "-list", "-project", project_path]
            list_proc = subprocess.run(list_cmd, capture_output=True, text=True, timeout=30)
            scheme = _parse_scheme(list_proc)

        if not scheme:
            err_detail = list_proc.stderr.strip() if list_proc.returncode != 0 else "No schemes listed"
            result["errors"].append(f"No scheme found in project. xcodebuild output: {err_detail}")
            return result

        print(f"Building with scheme: {scheme}")

        # Run actual build (simulator, no code signing)
        build_cmd = [
            "xcodebuild", "build",
            "-project", project_path,
            "-scheme", scheme,
            "-destination", "generic/platform=iOS Simulator",
            "-quiet",
            "CODE_SIGNING_ALLOWED=NO"
        ]
        build_proc = subprocess.run(
            build_cmd, capture_output=True, text=True, timeout=180
        )

        if build_proc.returncode == 0:
            result["can_build"] = True
        else:
            error_lines = []
            for line in (build_proc.stderr + build_proc.stdout).split('\n'):
                if ": error:" in line:
                    error_lines.append(line.strip())
            result["errors"] = error_lines[:20] if error_lines else [
                f"Build failed with exit code {build_proc.returncode}. Last output: {build_proc.stderr[-500:]}"
            ]

    except subprocess.TimeoutExpired:
        result["errors"].append("xcodebuild timed out (180s)")
    except FileNotFoundError:
        result["errors"].append("xcodebuild not found - Xcode not installed")
    except Exception as e:
        result["errors"].append(f"Build check failed: {str(e)}")

    return result


# ---------------------------------------------------------------------------
# Build retry helper (used in multiple places)
# ---------------------------------------------------------------------------

def _run_build_retry_loop(task: dict, ios_context: dict, result: dict,
                           changes: list, model_name: str,
                           max_retries: int, label: str = "") -> tuple:
    """Run build-check-and-fix loop. Returns (build_result, result, changes)."""
    build_result = run_ios_build_check()
    retry_count = 0

    while (not build_result.get("can_build")
           and build_result.get("errors")
           and retry_count < max_retries):
        retry_count += 1
        prefix = f"[{label}] " if label else ""
        print(f"{prefix}Build failed (attempt {retry_count}/{max_retries}). Errors:")
        for err in build_result["errors"]:
            print(f"  {err}")

        result = call_llm_fix(task, ios_context, result, build_result["errors"], model_name)
        new_changes = result.get("changes", [])
        if new_changes:
            write_changes(new_changes, ios_context)
            changes = new_changes
            build_result = run_ios_build_check()
        else:
            print(f"{prefix}LLM returned no fix changes, stopping build retries.")
            break

    return build_result, result, changes


# ---------------------------------------------------------------------------
# Task processing — 3-phase pipeline
# ---------------------------------------------------------------------------

def process_task(task_path: Path, ios_context: dict) -> dict:
    """Process a single task through the 3-phase pipeline:

    Phase 1: Initial LLM generation
    Phase 2: Build check + retry loop (up to MAX_BUILD_RETRIES)
    Phase 3: Design review + fix loop (up to MAX_DESIGN_RETRIES)
    """
    task = load_task(task_path)
    print(f"\n{'='*60}")
    print(f"Processing task: {task_path.name}")
    print(f"Task type: {task.get('type', 'unknown')}")

    model_name = task.get("model", DEFAULT_MODEL)
    print(f"Using model: {model_name}")

    # ── Phase 1: Initial Generation ──────────────────────────────
    print(f"\n--- Phase 1: Initial Generation ---")
    result = call_llm(task, ios_context, model_name)

    # Save raw model output for debugging
    output_file = REPO_ROOT / "agent" / "output.json"
    enhanced_output = {
        "task": task,
        "ios_context": ios_context,
        "model_result": result
    }
    output_file.write_text(json.dumps(enhanced_output, indent=2), encoding="utf-8")

    title = result.get("title", "ios-agent-update")
    summary = result.get("summary", "")
    changes = result.get("changes", [])

    # Fallback if LLM returned no changes
    if not isinstance(changes, list) or len(changes) == 0:
        print("Model returned no changes -- applying fallback.")
        dels = task.get("deliverables", [])
        changes = []
        for d in dels:
            p = d.get("path")
            t = (d.get("type") or "new").lower()
            if not p or t != "new":
                continue
            changes.append({
                "path": p,
                "action": "create",
                "content": synthesize_ios_content(p, ios_context, task)
            })

        if not changes:
            fallback_path = "ios/PT-Helper/PT-Helper/AgentGenerated.swift"
            changes = [{
                "path": fallback_path,
                "action": "create",
                "content": synthesize_ios_content(fallback_path, ios_context, task)
            }]

        summary = summary or "iOS Agent: synthesized iOS-specific files for deliverables."

    write_changes(changes, ios_context)

    # ── Phase 2: Build Retry Loop ────────────────────────────────
    print(f"\n--- Phase 2: Build Check (max {MAX_BUILD_RETRIES} retries) ---")
    build_result, result, changes = _run_build_retry_loop(
        task, ios_context, result, changes, model_name,
        max_retries=MAX_BUILD_RETRIES, label="Build"
    )
    print(f"Build Check: {'PASS' if build_result.get('can_build') else 'FAIL'}")

    # ── Phase 3: Design Review Loop (only if build passed) ──────
    design_review_result = None

    if build_result.get("can_build"):
        print(f"\n--- Phase 3: Design Review (max {MAX_DESIGN_RETRIES} iterations) ---")

        for design_iteration in range(MAX_DESIGN_RETRIES):
            print(f"\nDesign Review iteration {design_iteration + 1}/{MAX_DESIGN_RETRIES}")

            design_review_result = design_review(task, ios_context, changes, model_name)

            score = design_review_result.get("score", 0)
            passes = design_review_result.get("passes", False)
            summary_text = design_review_result.get("summary", "")
            print(f"  Score: {score}/10 | Passes: {passes}")
            print(f"  Summary: {summary_text}")

            if passes:
                print("  Design review PASSED.")
                break

            # Log issues
            for issue in design_review_result.get("issues", []):
                sev = issue.get("severity", "?")
                fname = issue.get("file", "?")
                desc = issue.get("issue", "")
                print(f"  [{sev}] {fname}: {desc}")

            # Ask LLM to fix design
            print("  Requesting design improvements from LLM...")
            result = call_llm_design_fix(
                task, ios_context, result, design_review_result, model_name
            )
            new_changes = result.get("changes", [])

            if not new_changes:
                print("  LLM returned no design fix changes, stopping design retries.")
                break

            write_changes(new_changes, ios_context)
            changes = new_changes

            # Re-build after design changes (they may break compilation)
            print(f"  Post-design build check (max {MAX_POST_DESIGN_BUILD_RETRIES} retries)...")
            build_result, result, changes = _run_build_retry_loop(
                task, ios_context, result, changes, model_name,
                max_retries=MAX_POST_DESIGN_BUILD_RETRIES, label="Post-Design"
            )

            if not build_result.get("can_build"):
                print("  Build failed after design fixes. Stopping design iterations.")
                break
        else:
            # Loop completed without breaking — design didn't pass
            if design_review_result and not design_review_result.get("passes", False):
                print("  Design review did not fully pass after all iterations.")
    else:
        print("\nSkipping design review (build did not pass).")

    # ── Finalize ─────────────────────────────────────────────────
    print(f"\nFinal Build: {'PASS' if build_result.get('can_build') else 'FAIL'}")
    if design_review_result:
        print(f"Final Design: Score {design_review_result.get('score', 'N/A')}/10 | "
              f"{'PASS' if design_review_result.get('passes') else 'FAIL'}")

    # Move task to processed
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    task_path.rename(PROCESSED_DIR / task_path.name)

    return {
        "task_name": task_path.name,
        "title": title,
        "summary": summary,
        "changes": changes,
        "build_result": build_result,
        "design_review": design_review_result
    }


# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

def main():
    print("Starting iOS Agent...")
    print(f"Build retries: {MAX_BUILD_RETRIES} | Design iterations: {MAX_DESIGN_RETRIES} | Post-design build retries: {MAX_POST_DESIGN_BUILD_RETRIES}")

    ios_context = analyze_ios_project()
    print(f"iOS Context: {json.dumps(ios_context, indent=2)}")

    queued = sorted(glob.glob(str(QUEUED_DIR / "*.json")))
    if not queued:
        print("No tasks found in queued/")
        return

    print(f"Found {len(queued)} queued task(s)")

    all_results = []

    for task_file in queued:
        task_path = Path(task_file)
        result = process_task(task_path, ios_context)
        all_results.append(result)

        # Re-analyze context so subsequent tasks see newly created files
        ios_context = analyze_ios_project()

    # Generate PR body from all results
    pr_body_parts = ["### iOS Agent Tasks\n"]
    all_changes = []
    combined_title = ""

    for r in all_results:
        combined_title = r["title"]
        build_status = "PASS" if r["build_result"].get("can_build") else "FAIL"

        # Include design review status
        dr = r.get("design_review")
        if dr:
            design_score = dr.get("score", "N/A")
            design_status = "PASS" if dr.get("passes") else "FAIL"
            pr_body_parts.append(
                f"**{r['title']}**: {r['summary']} "
                f"(Build: {build_status} | Design: {design_status}, Score: {design_score}/10)"
            )
        else:
            pr_body_parts.append(f"**{r['title']}**: {r['summary']} (Build: {build_status})")

        pr_body_parts.append("")
        all_changes.extend(r["changes"])

    if len(all_results) > 1:
        combined_title = f"agent-multi-{len(all_results)}-tasks"

    pr_body_parts.append(f"**Total files modified:** {len(all_changes)}")
    pr_body_parts.append("\n**Files:**")
    for ch in all_changes:
        pr_body_parts.append(f"- {ch['action'].title()}: `{ch['path']}`")

    pr_body = '\n'.join(pr_body_parts)
    (REPO_ROOT / "agent" / "last_pr_body.txt").write_text(pr_body, encoding="utf-8")
    (REPO_ROOT / "agent" / "last_branch_name.txt").write_text(
        f"ios-{combined_title.lower().replace(' ', '-')}",
        encoding="utf-8"
    )

    print(f"\nAgent completed. Processed {len(all_results)} task(s).")


if __name__ == "__main__":
    sys.exit(main())
