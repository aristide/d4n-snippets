# Contributing

Thank you for contributing to this examples repository!

## Adding a new code example

1. Place your file in `domains/{domain}/code/en/`
2. Update `domains/{domain}/manifest.yaml` with the file metadata
3. Run validation: `python scripts/validate.py .`
4. Rebuild the registry: `python scripts/build_registry.py .`

## Adding translations

1. Copy the English file to `domains/{domain}/code/{locale}/` (keep the same filename)
2. Translate the content
3. Add the locale to the domain's `locales` list in `manifest.yaml`
4. Add `i18n.{locale}` entries for title/description in `manifest.yaml`
