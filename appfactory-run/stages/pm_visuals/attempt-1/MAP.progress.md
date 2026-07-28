# ThreadGrid · pm_visuals progress

Queue (serial, one frame per generation):

| frame_id | prompt | raster | status |
|----------|--------|--------|--------|
| frame_charts_home | prompts/frame_charts_home.txt | frames/frame_charts_home.png | done |
| frame_charts_empty | prompts/frame_charts_empty.txt | frames/frame_charts_empty.png | done |
| frame_create_preview | prompts/frame_create_preview.txt | frames/frame_create_preview.png | done |
| frame_chart_editor | prompts/frame_chart_editor.txt | frames/frame_chart_editor.png | done |
| frame_stitch_session | prompts/frame_stitch_session.txt | frames/frame_stitch_session.png | done |
| frame_chart_export | prompts/frame_chart_export.txt | frames/frame_chart_export.png | done |

Backend note: primary Codex wrapper failed (codex auth.json API key 401 on api.openai.com); all frames via ClaudeGPTImage HTTP fallback against factory AI relay with factory keychain key (backend=claude_gpt_image_http_factory_relay), one call per frame. Relay renders ~851x1848 (ratio preserved from 640x1392).

Slots (best-effort): charts_hero done (1774x887), charts_empty_illustration done (1254x1254), app_icon done (1254x1254). Skipped by design: create_source_photo / chart_thumbnail / finished_piece_photo (user-capture / runtime-render photo_or_media).

Final: Status **ready** — see MAP.md.
