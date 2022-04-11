# Releasing a new version

These notes reflect the current process.

## Update CHANGELOG.md

Move the content of the unreleased entry to a new `<VERSION>` entry at
the top of [CHANGELOG.md], where `<VERSION>` is the new version
number.

Commit the changes in a commit with the message `ZAbort <VERSION>`.

[CHANGELOG.md]: https://github.com/paltherr/zabort/blob/main/CHANGELOG.md

## Create a tag

Create a new annotated tag with:

```bash
$ git tag -a <VERSION>
```

Include the [CHANGELOG.md] notes corresponding to the new version as
the tag annotation, except the first line should be: `ZAbort <VERSION> -
YYYY-MM-DD` and any Markdown headings should become plain text,
e.g.:

```md
### Added
```

should become:

```md
Added:
```

## Create a GitHub release

Push the new version commit and tag to GitHub via the following:

```bash
$ git push --follow-tags
```

Then visit https://github.com/paltherr/zabort/releases, and:

* Click **Draft a new release**.
* Select the new version tag.
* Name the release: `ZAbort <VERSION>`.
* Paste the same notes from the version tag annotation as the
  description, except change the first line to read: `Released:
  YYYY-MM-DD`.
* Click **Publish release**.

For more on `git push --follow-tags`, see:

* [git push --follow-tags in the online manual][ft-man]
* [Stack Overflow: How to push a tag to a remote repository using Git?][ft-so]

[ft-man]: https://git-scm.com/docs/git-push#git-push---follow-tags
[ft-so]: https://stackoverflow.com/a/26438076

## Homebrew

The basic instructions are in the [Submit a new version of an existing
formula][brew] section of the Homebrew docs.

[brew]: https://github.com/Homebrew/brew/blob/master/docs/How-To-Open-a-Homebrew-Pull-Request.md#submit-a-new-version-of-an-existing-formula

An example using v0.1.0 (notice that this uses the sha256 sum of the
tarball):

```bash
$ curl -LOv https://github.com/paltherr/zabort/archive/v0.1.0.tar.gz
$ openssl sha256 v0.1.0.tar.gz
SHA256(v0.1.0.tar.gz)= 16224e9d0df6386f92a9e7fa5c099d81c02e5c8109687d026fcc74fe66a65c07

# Add the --dry-run flag to see the individual steps without executing.
$ brew bump-formula-pr \
  --url=https://github.com/paltherr/zabort/archive/v0.1.0.tar.gz \
  --sha256=16224e9d0df6386f92a9e7fa5c099d81c02e5c8109687d026fcc74fe66a65c07
```
