# Game typography trial — Source Han Sans

2026-10-02 accepted mixed-role revision: body and actions retain Source Han Sans TW 400/600. Seven major panel headings and the world home inscription use `UiTypography.chapter_font()`, the existing Noto Serif TC variable font at weight 800 (real axis weight; no synthetic outline bolding). Small section lists, status, world building labels and buttons remain sans. The serif asset is restored to Web release and `NotoSerifTC-LICENSE.txt` is included alongside the Source Han Sans license.

Noto Serif TC provenance check: embedded metadata identifies Noto Serif TC, Adobe, copyright 2017–2023 Adobe, SIL OFL 1.1 and weight axis 200–900. Full metadata is recorded by tools/font_trial_audit.gd. The original download provenance of this pre-existing font remains unknown; no claim of an upstream byte-for-byte match is made. Its original copyright notice is retained with the OFL text from the official Google Fonts Noto Serif TC directory. The binary was not edited.

2026-10-01: User requested a game-wide trial of Adobe Source Han Sans.

- File: `SourceHanSansTW-VF.ttf`, official release **2.005R**, Taiwan region-specific variable TrueType font, unmodified upstream binary. This is Adobe's published TW configuration, not a custom project-generated subset.
- Download: https://raw.githubusercontent.com/adobe-fonts/source-han-sans/2.005R/Variable/TTF/Subset/SourceHanSansTW-VF.ttf
- SHA-256: `CF6889F4C0F1ADEAF814CA3E98CC692D9E2D706501CF7545B9B58F6E3966B6AC`
- Copyright Adobe; licensed under SIL Open Font License 1.1. Complete upstream notice and conditions retained in `SourceHanSans-LICENSE.txt`. Font may be embedded/distributed with the game; it must not be sold standalone. Modified font versions must respect the reserved font name restriction. No custom modification was made.
- Roles: UiTypography body weight 400; emphasis weight 600. Theme also assigns RichTextLabel normal/bold roles. Font size and Control layout contracts are unchanged, subject to font-metric regression checks.
- Godot: default grayscale antialiasing and automatic hinting; no blanket MSDF change. Font choice does not by itself guarantee smooth rendering at every world-camera zoom or Web DPR.
- The existing `NotoSerifTC-VF.ttf` is retained as an earlier-design source asset for comparison/reversion and excluded from Web release. Its provenance/license is not established by this Source Han Sans record. Web release explicitly includes `SourceHanSans-LICENSE.txt`.

Official project and configuration information: https://github.com/adobe-fonts/source-han-sans/blob/2.005R/README-TW.md
