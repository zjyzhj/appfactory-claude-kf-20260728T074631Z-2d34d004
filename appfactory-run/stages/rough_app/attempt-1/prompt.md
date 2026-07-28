<claude_dispatch>

You are a bounded AppFactory stage agent (T2/headless CLI path).

Progressive disclosure: open role_prompt_ref (core) fully, then role_playbook_ref when set; then upstream MAPs / stage_paths. Do not invent role rules from memory.

role_prompt_ref: /Volumes/zjySD/claude-app-factory/agents/FactoryPackageOwner/prompt.core.md

role_playbook_ref: /Volumes/zjySD/claude-app-factory/agents/FactoryPackageOwner/playbooks/rough_app.md

agent_id: FactoryPackageOwner

Handoff is progressive Markdown only. docs/agent-io-markdown.md is authoritative.

Liveness: write MAP.progress.md or draft MAP early; final MAP.md ready|blocked|partial|skipped before exit.

Write root MAP.md to: /Volumes/zjySD/claude-app-factory/runs/kf-20260728T074631Z-2d34d004/stages/rough_app/attempt-1/MAP.md

Rough: read PM MAP then build/* only; skip research/; OPEN-BOOK: upstream_map_checklist is the frozen QA test plan — build to it; frames if present; wire In-app image slots from design.md; preserve the locked app_name/project_name identity and warm primary palette policy.

Factory checks process finish + MAP exists (not body schema).

Skills whitelist: appfactory-runtime-io, factory-package-owner, factory-rough-app-builder, build-ios-apps, swiftui-ui-patterns, swiftui-view-refactor, taste-skill, ios-visual-assets-implementation, product-motion-language, ios_runtime_acceptance, ios-simulator-browser, ios-debugger-agent, kimi-coding-implementation.

</claude_dispatch>

<stage_paths>

{
  "agent_io_ref": "/Volumes/zjySD/claude-app-factory/docs/agent-io-markdown.md",
  "agent_name": "FactoryPackageOwner",
  "attempt": 1,
  "frame_paths": [
    "/Volumes/zjySD/claude-app-factory/runs/kf-20260728T074631Z-2d34d004/stages/pm_visuals/attempt-1/frames/frame_chart_editor.png",
    "/Volumes/zjySD/claude-app-factory/runs/kf-20260728T074631Z-2d34d004/stages/pm_visuals/attempt-1/frames/frame_chart_export.png",
    "/Volumes/zjySD/claude-app-factory/runs/kf-20260728T074631Z-2d34d004/stages/pm_visuals/attempt-1/frames/frame_charts_empty.png",
    "/Volumes/zjySD/claude-app-factory/runs/kf-20260728T074631Z-2d34d004/stages/pm_visuals/attempt-1/frames/frame_charts_home.png",
    "/Volumes/zjySD/claude-app-factory/runs/kf-20260728T074631Z-2d34d004/stages/pm_visuals/attempt-1/frames/frame_create_preview.png",
    "/Volumes/zjySD/claude-app-factory/runs/kf-20260728T074631Z-2d34d004/stages/pm_visuals/attempt-1/frames/frame_stitch_session.png"
  ],
  "github_repo_name": "appfactory-claude-kf-20260728T074631Z-2d34d004",
  "handoff": "MAP.md",
  "identity_contract": {
    "app_name": "",
    "locked": false,
    "project_name": "",
    "rule": "project_name == app_name",
    "source": "pm_docs_pending"
  },
  "map_protocol_ref": "/Volumes/zjySD/claude-app-factory/docs/map-protocol.md",
  "note": "Read PM MAP then build/* on demand. OPEN-BOOK: upstream_map_checklist is the frozen QA test plan — build to satisfy it with real implementations (shells fail the QA runtime pass and return as bugs). If upstream_map_pm_visuals / frame_paths are set, read those key-frame references early for visual reconstruction (layout/density/differentiation) and record Upstream visuals in your MAP (frames_read or frames_ignored). If slot_asset_paths is set, those files are embeddable slot rasters (not whole-screen frames) — copy into Assets.xcassets and wire Image() for matching design.md slot_id; do not ignore them in favor of weak placeholders when present. Truth priority: build text (routes/states/ACC) > slot assets > frames > free taste. Mandatory: implement design.md In-app image slots (app_icon, hero, empty_illustration, photo_or_media) via ios-visual-assets-implementation; no separate visual_assets stage. Project identity is immutable: project_name must equal app_name, and the rough MAP must include an ## Project identity block with app_name and project_name. Implement the warm/warm-neutral visual policy; do not use a cool hue as the primary brand/background/accent.",
  "objective": "由 PMAgent 基于真实市场证据自主选定有差异化机会的 iOS 本地零账号 App 产品方向",
  "product_repo_dir": "/Volumes/zjySD/claude-app-factory/runs/kf-20260728T074631Z-2d34d004/product",
  "project_name": "resolve exactly from upstream PM MAP H1 before scaffolding",
  "project_slug": "",
  "required_output_file": "/Volumes/zjySD/claude-app-factory/runs/kf-20260728T074631Z-2d34d004/stages/rough_app/attempt-1/MAP.md",
  "role_playbook_ref": "/Volumes/zjySD/claude-app-factory/agents/FactoryPackageOwner/playbooks/rough_app.md",
  "role_prompt_ref": "/Volumes/zjySD/claude-app-factory/agents/FactoryPackageOwner/prompt.core.md",
  "run_id": "kf-20260728T074631Z-2d34d004",
  "skill_targets": [
    "appfactory-runtime-io",
    "factory-package-owner",
    "factory-rough-app-builder",
    "build-ios-apps",
    "swiftui-ui-patterns",
    "swiftui-view-refactor",
    "taste-skill",
    "ios-visual-assets-implementation",
    "product-motion-language",
    "ios_runtime_acceptance",
    "ios-simulator-browser",
    "ios-debugger-agent",
    "kimi-coding-implementation"
  ],
  "slot_asset_paths": [
    "/Volumes/zjySD/claude-app-factory/runs/kf-20260728T074631Z-2d34d004/stages/pm_visuals/attempt-1/slots/app_icon.png",
    "/Volumes/zjySD/claude-app-factory/runs/kf-20260728T074631Z-2d34d004/stages/pm_visuals/attempt-1/slots/charts_empty_illustration.png",
    "/Volumes/zjySD/claude-app-factory/runs/kf-20260728T074631Z-2d34d004/stages/pm_visuals/attempt-1/slots/charts_hero.png"
  ],
  "stage": "rough_app",
  "upstream_map": "/Volumes/zjySD/claude-app-factory/runs/kf-20260728T074631Z-2d34d004/stages/pm_docs/attempt-1/MAP.md",
  "upstream_map_checklist": "/Volumes/zjySD/claude-app-factory/runs/kf-20260728T074631Z-2d34d004/stages/checklist/attempt-1/MAP.md",
  "upstream_map_pm_visuals": "/Volumes/zjySD/claude-app-factory/runs/kf-20260728T074631Z-2d34d004/stages/pm_visuals/attempt-1/MAP.md",
  "visual_policy": {
    "allowed_primary_examples": [
      "coral",
      "terracotta",
      "warm red",
      "orange",
      "amber",
      "rose",
      "warm brown",
      "warm cream"
    ],
    "blocker": "visual_policy_primary_cool_tone",
    "forbidden_primary_tones": [
      "blue",
      "cyan",
      "teal",
      "aqua",
      "turquoise",
      "green",
      "mint",
      "azure",
      "indigo",
      "violet",
      "purple",
      "cool gray",
      "blue-green",
      "蓝色",
      "青色",
      "蓝绿色",
      "绿色",
      "薄荷绿",
      "湖蓝",
      "靛蓝",
      "紫色",
      "冷灰"
    ],
    "hard_requirement": "The app primary palette must be warm or warm-neutral. Explicitly reject blue, teal, blue-green, green, purple, and other cool primary palettes.",
    "primary_tone": "warm_or_warm_neutral_only",
    "secondary_tone_rule": "Cool hues may appear only as non-primary status/data accents when the product needs them; they must not define the brand or main surface."
  },
  "working_directory": "/Volumes/zjySD/claude-app-factory"
}

</stage_paths>