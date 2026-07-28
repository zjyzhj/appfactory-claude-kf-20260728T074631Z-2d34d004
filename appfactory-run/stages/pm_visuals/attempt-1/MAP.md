# ThreadGrid · pm_visuals key-frame map

**Status: ready**

6/6 design-planned Visual frames generated as real PNGs, plus 3/3 planned embeddable slot rasters. Every raster verified: valid PNG signature, non-trivial bytes, adjacent `.png.receipt.json` with `ok=true`. Prompts in `prompts/<frame_id>.txt` / `prompts/slot-<slot_id>.txt`.

Backend note: primary Codex wrapper path failed (`~/.codex/auth.json` string OPENAI_API_KEY → 401 from api.openai.com; first attempt also hit 300s codex_exec timeout). All rasters produced via ClaudeGPTImage (`claude-gpt-image`) HTTP fallback against factory AI relay `http://38.143.109.229:48761/v1` with factory keychain relay key (`backend=claude_gpt_image_http_factory_relay`, model `gpt-image-2`, one call per raster). Relay renders its own canvas: frames ~851x1848 (iPhone portrait ratio preserved from requested 640x1392), slots 1774x887 (hero 2:1) / 1254x1254 (squares).

## Frames (whole-screen layout references for rough_app multimodal)

| frame_id | route_id | raster | prompt | size | status |
|----------|----------|--------|--------|------|--------|
| frame_charts_home | tab_charts | frames/frame_charts_home.png | prompts/frame_charts_home.txt | 851x1849 | done |
| frame_charts_empty | tab_charts | frames/frame_charts_empty.png | prompts/frame_charts_empty.txt | 851x1849 | done |
| frame_create_preview | create_wizard | frames/frame_create_preview.png | prompts/frame_create_preview.txt | 851x1847 | done |
| frame_chart_editor | chart_editor | frames/frame_chart_editor.png | prompts/frame_chart_editor.txt | 852x1846 | done |
| frame_stitch_session | stitch_session | frames/frame_stitch_session.png | prompts/frame_stitch_session.txt | 853x1844 | done |
| frame_chart_export | chart_export | frames/frame_chart_export.png | prompts/frame_chart_export.txt | 851x1848 | done |

Visual spot-check: home frame shows hoop hero + status chips + two pattern cards with real stitch-cell thumbnails and progress rings on warm linen; editor frame shows full-bleed symbol grid with R12·C34 selection, DMC palette strip (321/740/310/762/823/3346) and undo chrome; create preview shows source fox photo → symbol grid conversion with size/color sliders; empty state is hoop illustration + headline + red CTA. Palette matches design (#F5EFE4 linen / #C0453E thread-red / #3E5F8A indigo / #5F8A4C sage); monospaced codes throughout.

## Slot assets (embeddable rasters, no UI chrome)

| slot_id | kind | raster | size | status | notes |
|---------|------|--------|------|--------|-------|
| charts_hero | hero | slots/charts_hero.png | 1774x887 | done | hoop + red thread + 3 skeins on linen, no text |
| charts_empty_illustration | empty_illustration | slots/charts_empty_illustration.png | 1254x1254 | done | empty hoop + needle + skeins, no text |
| app_icon | app_icon | slots/app_icon.png | 1254x1254 | done | needle stitching red x on Aida lattice, indigo accent, full-bleed |

Skipped slots (by design): `create_source_photo`, `chart_thumbnail`, `finished_piece_photo` are user-capture / runtime-render `photo_or_media` slots — no packaged raster per contract.

## Downstream consumption

- rough_app multimodal: read the 6 `frames/*.png` as layout skeletons per route_id; do not embed frames as binaries.
- Asset Catalog wiring: use `slots/<slot_id>.png` as imageset source for `charts_hero`, `charts_empty_illustration`, `app_icon` (app_icon needs resize to 1024x1024 from 1254x1254).

## Gaps

None.
