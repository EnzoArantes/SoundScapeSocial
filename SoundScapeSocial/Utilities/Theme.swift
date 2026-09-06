//
//  Theme.swift
//  SoundScapeSocial
//
//  Palette contract. There is no code here on purpose.
//
//  Every app color lives in Assets.xcassets as a color set with both a Light
//  and a Dark appearance, so the UI follows the system setting. The build
//  setting ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS
//  generates the Swift symbols, so `Color.appBackground` and
//  `.foregroundColor(.textPrimary)` resolve straight from the catalog and a
//  typo is a compile error rather than a silently missing color.
//
//  Pick a color by ROLE:
//
//    appBackground   Page background. The bottom layer of every screen.
//    appSurface      Raised surfaces: cards, text fields, image placeholders.
//    textPrimary     Body text on appBackground or appSurface.
//    textSecondary   Supporting text, captions, unselected icons.
//    brandAccent     Brand purple used as TEXT, icons, or tint on a page.
//    brandFill       Brand purple used as a FILL behind onBrand text.
//    onBrand         Text and icons drawn on top of brandFill.
//
//  Do not swap brandAccent and brandFill. Each is contrast tuned for one job
//  in both appearances: brandAccent is light enough to read on a dark page,
//  brandFill is dark enough for white text to read on top of it.
//
//  Fixed, non-adaptive colors are correct in exactly one situation: content
//  drawn over artwork, where the scrim rather than the system appearance sets
//  the contrast. SwipeCardView's caption (white on a black scrim over album
//  art) is the one intentional case.
//
