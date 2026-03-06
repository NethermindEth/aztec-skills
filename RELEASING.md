# Releasing

This repository uses a manual release flow. CI validates formatting, type checks, installer smoke tests, and packaged tarball contents, but publishing to npm is not automated.

## Release Checklist

1. Update the version in `package.json`.
2. Update any pinned install examples in `README.md`.
3. Install dependencies and run the full validation suite:

```bash
bun install --frozen-lockfile
bun run ci
```

4. Commit the release changes:

```bash
git add package.json README.md RELEASING.md
git commit -m "chore(release): bump version to <version>"
```

5. Create and push the git tag. Follow the existing tag pattern by prefixing the package version with `v`:

```bash
git tag v<version>
git push origin main
git push origin v<version>
```

6. Publish the package to npm using the `devnet` dist-tag:

```bash
npm publish --tag devnet
```

7. Verify the published version and dist-tags:

```bash
npm view install-aztec-skills version dist-tags --json
```

## Current Release Example

For version `4.0.0-devnet.2-patch.1-v0.2.0`:

```bash
git add package.json README.md RELEASING.md
git commit -m "chore(release): bump version to 4.0.0-devnet.2-patch.1-v0.2.0"

git tag v4.0.0-devnet.2-patch.1-v0.2.0
git push origin main
git push origin v4.0.0-devnet.2-patch.1-v0.2.0

npm publish --tag devnet
npm view install-aztec-skills version dist-tags --json
```
