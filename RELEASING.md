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

7. Verify the published dist-tags:

```bash
npm dist-tag ls install-aztec-skills
npm view install-aztec-skills dist-tags --json --registry=https://registry.npmjs.org/
```

8. If you want `latest` to point at the version you just published, update the dist-tag instead of publishing the same version again:

```bash
npm dist-tag add install-aztec-skills@<version> latest
npm dist-tag ls install-aztec-skills
npm view install-aztec-skills dist-tags --json --registry=https://registry.npmjs.org/
```

Important:

- Do not run `npm publish --tag latest` for a version that was already published with `--tag devnet`.
- npm forbids overwriting an existing published version and will return `E403`.
- Use `npm dist-tag add ... latest` to promote an existing published version to the `latest` tag.
- `npm view install-aztec-skills version dist-tags --json` is a poor verifier for tag promotion because the top-level `version` field does not tell you which release `latest` points to.
- Right after changing a dist-tag, npm read APIs can lag briefly. If the write succeeded but the read still shows old data, retry the read after a short delay.

## Current Release Example

For version `4.1.0-rc.1-v0.3.0`:

```bash
git add package.json README.md RELEASING.md
git commit -m "chore(release): bump version to 4.1.0-rc.1-v0.3.0"

git tag v4.1.0-rc.1-v0.3.0
git push origin main
git push origin v4.1.0-rc.1-v0.3.0

npm publish --tag devnet
npm dist-tag ls install-aztec-skills
npm view install-aztec-skills dist-tags --json --registry=https://registry.npmjs.org/

# If this release should also become `latest`
npm dist-tag add install-aztec-skills@4.1.0-rc.1-v0.3.0 latest
npm dist-tag ls install-aztec-skills
npm view install-aztec-skills dist-tags --json --registry=https://registry.npmjs.org/
```
