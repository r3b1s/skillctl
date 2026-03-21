# Releasing `skillctl`

## AUR automation

Publishing a GitHub release now triggers [`.github/workflows/release-aur.yml`](../.github/workflows/release-aur.yml). The same workflow can also be run manually with a `release_tag` input if you need to retry AUR publishing without cutting another release. That workflow:

1. Validates the release tag format (`v0.1.1`).
2. Downloads the GitHub tag archive and computes its SHA-256 checksum.
3. Renders `PKGBUILD` from [`packaging/aur/PKGBUILD.in`](../packaging/aur/PKGBUILD.in).
4. Clones the AUR Git repository for `skillctl`.
5. Regenerates `.SRCINFO`.
6. Commits and pushes the update to the AUR.

## One-time setup

AUR account with write access to the `skillctl` package.

Generate a dedicated SSH key for GitHub Actions:

```bash
ssh-keygen -t ed25519 -C "skillctl-aur-release" -f ~/.ssh/skillctl-aur-release
```

Add the public key to your AUR account:

```bash
cat ~/.ssh/skillctl-aur-release.pub
```

Then add the private key as an Actions secret:

- Secret name: `AUR_SSH_PRIVATE_KEY`
- Value: the full contents of `~/.ssh/skillctl-aur-release`

## Release flow

1. Update `CHANGELOG.md`.
2. Create and push the git tag, for example `v0.1.1`.
3. Create a GitHub release from that tag and publish it.
4. Watch the `Publish AUR Package` workflow in the Actions tab.

If the workflow succeeds, the AUR package repo should contain updated `PKGBUILD` and `.SRCINFO` for that release.

If you need to retry an existing release after fixing workflow configuration or secrets, open the workflow in the Actions tab, choose `Run workflow`, and enter the existing tag such as `v0.1.1` in the `release_tag` field.

## Notes

- `.SRCINFO` generation is done in an Arch Linux container so the workflow does not need a custom runner.
