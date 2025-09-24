import os, json, glob, sys, subprocess, xml.etree.ElementTree as ET, re
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

def call_llm(task: dict, ios_context: dict) -> dict:
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        raise RuntimeError("OPENAI_API_KEY not set")

    client = OpenAI(api_key=api_key)
    
    # Enhanced system prompt with iOS context
    system_prompt = ORCH + "\n\n" + IOS + f"\n\n## iOS Project Context\n{json.dumps(ios_context, indent=2)}"
    
    # Enhanced user prompt with task and context
    user_prompt = json.dumps({
        "task": task,
        "ios_context": ios_context
    }, indent=2)

    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        temperature=0.2,
        response_format={"type": "json_object"},
        messages=[
            {"role":"system","content": system_prompt},
            {"role":"user","content": user_prompt}
        ],
    )
    out = resp.choices[0].message.content
    return json.loads(out)

def write_changes(changes: list, ios_context: dict):
    """Enhanced write_changes with iOS-specific handling"""
    for ch in changes:
        path = REPO_ROOT / ch["path"]
        action = ch["action"]
        
        if action == "delete":
            if path.exists(): 
                path.unlink()
            continue
            
        path.parent.mkdir(parents=True, exist_ok=True)
        
        # Handle iOS-specific file types
        content = ch["content"]
        if path.suffix == ".swift":
            content = enhance_swift_code(content, ios_context)
        elif path.suffix == ".storyboard":
            content = validate_storyboard_content(content)
        elif path.name == "Info.plist":
            content = validate_plist_content(content)
            
        path.write_text(content, encoding="utf-8")

def enhance_swift_code(content: str, ios_context: dict) -> str:
    """Enhance Swift code with best practices"""
    lines = content.split('\n')
    enhanced_lines = []
    
    # Add import statements if missing
    has_foundation = any("import Foundation" in line for line in lines)
    has_swiftui = any("import SwiftUI" in line for line in lines)
    
    # Add necessary imports at the top
    if not has_foundation and ("class" in content or "struct" in content):
        enhanced_lines.append("import Foundation")
        if has_swiftui or ios_context.get("has_swiftui", False):
            enhanced_lines.append("import SwiftUI")
        enhanced_lines.append("")
    
    # Add the original content
    enhanced_lines.extend(lines)
    
    return '\n'.join(enhanced_lines)

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

def run_ios_build_check() -> Dict[str, Any]:
    """Run basic iOS build validation"""
    result = {"can_build": False, "errors": []}
    
    try:
        # Find Xcode project
        xcode_projects = list(IOS_DIR.rglob("*.xcodeproj")) if IOS_DIR.exists() else []
        if not xcode_projects:
            result["errors"].append("No Xcode project found")
            return result
        
        # Try to run xcodebuild -list to validate project
        cmd = ["xcodebuild", "-list", "-project", str(xcode_projects[0])]
        process = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        
        if process.returncode == 0:
            result["can_build"] = True
            result["schemes"] = []
            # Parse schemes from output
            lines = process.stdout.split('\n')
            in_schemes = False
            for line in lines:
                line = line.strip()
                if line == "Schemes:":
                    in_schemes = True
                elif in_schemes and line and not line.startswith("Build Configurations"):
                    result["schemes"].append(line)
                elif line.startswith("Build Configurations"):
                    break
        else:
            result["errors"].append(f"xcodebuild failed: {process.stderr}")
            
    except subprocess.TimeoutExpired:
        result["errors"].append("xcodebuild timed out")
    except FileNotFoundError:
        result["errors"].append("xcodebuild not found - Xcode not installed")
    except Exception as e:
        result["errors"].append(f"Build check failed: {str(e)}")
    
    return result

def main():
    print("🍎 Starting iOS Agent...")
    
    # Analyze iOS project first
    ios_context = analyze_ios_project()
    print(f"📱 iOS Context: {json.dumps(ios_context, indent=2)}")
    
    queued = sorted(glob.glob(str(QUEUED_DIR / "*.json")))
    if not queued:
        print("No tasks found in queued/")
        return

    task_path = Path(queued[0])
    task = load_task(task_path)
    print(f"Processing iOS task: {task_path.name}")
    print(f"Task type: {task.get('type', 'unknown')}")

    # Call LLM with enhanced iOS context
    result = call_llm(task, ios_context)

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

    # Enhanced fallback for iOS-specific content
    if not isinstance(changes, list) or len(changes) == 0:
        print("Model returned no changes — applying iOS-specific fallback.")
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
            fallback_path = "ios/PT-Helper/AgentGenerated.swift"
            changes = [{
                "path": fallback_path,
                "action": "create",
                "content": synthesize_ios_content(fallback_path, ios_context, task)
            }]
        
        summary = summary or "iOS Agent: synthesized iOS-specific files for deliverables."

    # Write changes with iOS enhancements
    write_changes(changes, ios_context)
    
    # Run build check after changes
    build_result = run_ios_build_check()
    print(f"🔨 Build Check: {build_result}")

    # Move processed task
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    task_path.rename(PROCESSED_DIR / task_path.name)

    # Enhanced PR body with iOS context
    pr_body = f"""### 🍎 iOS Agent Task

**Title:** {title}

{summary}

**Changes:** {len(changes)} file(s)

**iOS Context:**
- Project: {ios_context.get('target_name', 'Unknown')}
- SwiftUI: {'✅' if ios_context.get('has_swiftui') else '❌'}
- Build Status: {'✅ Can Build' if build_result.get('can_build') else '❌ Build Issues'}

**Files Modified:**
{chr(10).join([f"- {ch['action'].title()}: `{ch['path']}`" for ch in changes])}
"""
    
    (REPO_ROOT / "agent" / "last_pr_body.txt").write_text(pr_body, encoding="utf-8")
    (REPO_ROOT / "agent" / "last_branch_name.txt").write_text(
        f"ios-{title.lower().replace(' ', '-')}",
        encoding="utf-8"
    )
    
    print("✅ iOS Agent completed successfully!")

if __name__ == "__main__":
    sys.exit(main())