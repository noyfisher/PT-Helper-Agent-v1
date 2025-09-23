import os, json, glob, sys
from pathlib import Path
from openai import OpenAI

REPO_ROOT = Path(__file__).resolve().parents[1]
PROMPTS_DIR = REPO_ROOT / "prompts"
TASKS_DIR = REPO_ROOT / "agent" / "tasks"
QUEUED_DIR = TASKS_DIR / "queued"
PROCESSED_DIR = TASKS_DIR / "processed"

ORCH = (PROMPTS_DIR / "orchestrator.md").read_text()
IOS  = (PROMPTS_DIR / "ios_dev.md").read_text()

def load_task(task_path: Path) -> dict:
    return json.loads(task_path.read_text())

def call_llm(task: dict) -> dict:
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        raise RuntimeError("OPENAI_API_KEY not set")

    client = OpenAI(api_key=api_key)

    system_prompt = ORCH + "\n\n" + IOS
    user_prompt = json.dumps(task, indent=2)

    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        temperature=0.2,
        response_format={"type": "json_object"},
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ],
    )
    out = resp.choices[0].message.content
    return json.loads(out)

def write_changes(changes: list):
    for ch in changes:
        path = REPO_ROOT / ch["path"]
        action = ch["action"]
        if action == "delete":
            if path.exists():
                path.unlink()
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(ch["content"], encoding="utf-8")

def main():
    queued = sorted(glob.glob(str(QUEUED_DIR / "*.json")))
    if not queued:
        print("No tasks found in queued/")
        return

    task_path = Path(queued[0])
    task = load_task(task_path)
    print(f"Processing task: {task_path.name}")

    result = call_llm(task)

    # ✅ NEW: Save raw LLM output for debugging
    (REPO_ROOT / "agent" / "output.json").write_text(
        json.dumps(result, indent=2),
        encoding="utf-8"
    )

    title = result.get("title", "Agent Update")
    summary = result.get("summary", "")
    changes = result.get("changes", [])

    if not isinstance(changes, list) or not changes:
        raise RuntimeError("Agent returned no changes")

    write_changes(changes)

    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    task_path.rename(PROCESSED_DIR / task_path.name)

    pr_body = f"### Agent Task\n\n**Title:** {title}\n\n{summary}\n\nChanges: {len(changes)} file(s)."
    (REPO_ROOT / "agent" / "last_pr_body.txt").write_text(pr_body, encoding="utf-8")
    (REPO_ROOT / "agent" / "last_branch_name.txt").write_text(
        title.lower().replace(" ", "-"),
        encoding="utf-8"
    )

if __name__ == "__main__":
    sys.exit(main())
