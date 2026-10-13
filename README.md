# port0.sh documentation

The documentation book for port0.sh. Built with mdBook and served at
https://docs.port0.sh.

## Build

Requires mdBook 0.5 or later.

```sh
mdbook build
```

The static site is written to `book/`. It is a plain directory of HTML, CSS,
JavaScript, fonts, and a search index. It can be served by any static file host.

## Package

```sh
scripts/package.sh
```

Builds the book and writes `port0-docs.tar.gz`, which contains the contents of
`book/` at the archive root. Extract the archive into a static host's document
root, or upload its contents.

## Structure

```
book.toml              mdBook configuration
src/                   chapters, in SUMMARY.md order
theme/                 one theme: palette, wordmark, favicon, Victor Mono
scripts/package.sh     build and archive the static site
```

## Source

Radicle is the canonical source. GitHub is the mirror. Every repository README
states the canonical source and links back to it. See the
[repositories chapter](src/reference/repositories.md).
