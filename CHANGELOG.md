# Changelog

## [2.0.0](https://github.com/TerraCycleUS/loop-client/compare/v1.0.2...v2.0.0) (2026-08-22)


### ⚠ BREAKING CHANGES

* **deps:** the gem no longer installs on Ruby below 4.0.

### Build System

* **deps:** [ITG-409] require ruby 4.0 ([#15](https://github.com/TerraCycleUS/loop-client/issues/15)) ([b20cdd4](https://github.com/TerraCycleUS/loop-client/commit/b20cdd4fcadb338583a86d89fc0c097ff97ee1c5))


### Continuous Integration

* **release:** [ITG-409] branch every published release tag ([#17](https://github.com/TerraCycleUS/loop-client/issues/17)) ([7fad3dc](https://github.com/TerraCycleUS/loop-client/commit/7fad3dceb19a788cadf636dad6acdac71d9e18d0))

## [1.0.2](https://github.com/TerraCycleUS/loop-client/compare/v1.0.1...v1.0.2) (2026-08-22)


### Continuous Integration

* **release:** [ITG-409] resolve jira keys in release notes and cache the build ([#13](https://github.com/TerraCycleUS/loop-client/issues/13)) ([e9e0146](https://github.com/TerraCycleUS/loop-client/commit/e9e01464d06b4be210108f195150ab467f4a2908))

## [1.0.1](https://github.com/TerraCycleUS/loop-client/compare/v1.0.0...v1.0.1) (2026-08-22)


### Bug Fixes

* **client:** patch security vulnerabilities in gem dependencies ([9c2a47c](https://github.com/TerraCycleUS/loop-client/commit/9c2a47cd6b4bc5cd568a607de1a28d3f16235a07))


### Maintenance

* **release:** [ITG-409] add release please circleci workflow ([#8](https://github.com/TerraCycleUS/loop-client/issues/8)) ([6d591a9](https://github.com/TerraCycleUS/loop-client/commit/6d591a9a843f9f6ec0dba4d4729cf1517ee71038))
* **release:** [ITG-409] add release rules check and process docs ([#9](https://github.com/TerraCycleUS/loop-client/issues/9)) ([31f9c52](https://github.com/TerraCycleUS/loop-client/commit/31f9c52ff6f6519e1941d2fc756662132af2eceb))
* **release:** [ITG-409] validate pull request titles on ci ([#10](https://github.com/TerraCycleUS/loop-client/issues/10)) ([861ab12](https://github.com/TerraCycleUS/loop-client/commit/861ab12a35d88fc2fafff0b7655edf0ca4935719))


### Build System

* **deps:** update gems ([ITG-376]) ([cd448f8](https://github.com/TerraCycleUS/loop-client/commit/cd448f88fab836cda2e2cb11beb69813279e8bce))


### Code Refactoring

* **client:** add simplecov, improve test coverage, and remove dead code ([1fea794](https://github.com/TerraCycleUS/loop-client/commit/1fea79405b41b01282be889538623483b46103e7))
* **client:** update gems, remove dead code, and fix bugs ([d384d74](https://github.com/TerraCycleUS/loop-client/commit/d384d740404cfbb01d38de8099105eb09fcfa014))


### Continuous Integration

* **rules:** [ITG-409] require a jira issue on titles and branches ([#12](https://github.com/TerraCycleUS/loop-client/issues/12)) ([0ee0c19](https://github.com/TerraCycleUS/loop-client/commit/0ee0c19e5a9ecf1e279225f40a753ebbd8640c2c))
* **security:** [ITG-171] add gitleaks pre-commit hook and ci gate ([#6](https://github.com/TerraCycleUS/loop-client/issues/6)) ([f65b976](https://github.com/TerraCycleUS/loop-client/commit/f65b97673be1e53f9287a04becc0e414c6a4a240))


### Miscellaneous Chores

* **client:** add ruby-lsp to development dependencies ([2e863ba](https://github.com/TerraCycleUS/loop-client/commit/2e863ba5b25d80576df08172c8c0f8bf0def33e1))

[ITG-409]: https://terracycle.atlassian.net/browse/ITG-409
[ITG-171]: https://terracycle.atlassian.net/browse/ITG-171
[ITG-376]: https://terracycle.atlassian.net/browse/ITG-376
