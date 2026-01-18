# Changelog

## [2.0.0](https://github.com/Texarkanine/jekyll-highlight-cards/compare/v1.1.2...v2.0.0) (2026-01-18)


### ⚠ BREAKING CHANGES

* standardize config across Jekyll gem repos ([#26](https://github.com/Texarkanine/jekyll-highlight-cards/issues/26))
* Drop ostensible support for Ruby 3.1; only 3.3+ is promised

### Features

* standardize config across Jekyll gem repos ([#26](https://github.com/Texarkanine/jekyll-highlight-cards/issues/26)) ([93d93bc](https://github.com/Texarkanine/jekyll-highlight-cards/commit/93d93bc7e922712e3df81c36ab5bbb78749db630))


### Bug Fixes

* **deps-dev:** bump rubocop-rspec in the dev-deps-minor-patch group ([169a11f](https://github.com/Texarkanine/jekyll-highlight-cards/commit/169a11f9e9f57e7ed93bedb66c822e4a98ae0da8))


### Miscellaneous Chores

* standardize config across Jekyll gem repos ([93d93bc](https://github.com/Texarkanine/jekyll-highlight-cards/commit/93d93bc7e922712e3df81c36ab5bbb78749db630))

## [1.1.2](https://github.com/Texarkanine/jekyll-highlight-cards/compare/v1.1.1...v1.1.2) (2026-01-01)


### Bug Fixes

* **deps-dev:** bump rubocop from 1.82.0 to 1.82.1 in the dev-deps-minor-patch group ([#22](https://github.com/Texarkanine/jekyll-highlight-cards/issues/22)) ([1788b1e](https://github.com/Texarkanine/jekyll-highlight-cards/commit/1788b1e0e00d1b9a5bbf4eaf27e2bb1a1657ed48))
* **deps-dev:** bump rubocop in the dev-deps-minor-patch group ([1788b1e](https://github.com/Texarkanine/jekyll-highlight-cards/commit/1788b1e0e00d1b9a5bbf4eaf27e2bb1a1657ed48))

## [1.1.1](https://github.com/Texarkanine/jekyll-highlight-cards/compare/v1.1.0...v1.1.1) (2025-12-22)


### Bug Fixes

* **css:** Refactor imports to use '[@use](https://github.com/use)' syntax ([#20](https://github.com/Texarkanine/jekyll-highlight-cards/issues/20)) ([14d4f1d](https://github.com/Texarkanine/jekyll-highlight-cards/commit/14d4f1dbd94a1ba6ccc5642e27c8114fd09e288a))
* **deps-dev:** bump rubocop from 1.81.7 to 1.82.0 in the dev-deps-minor-patch group ([#19](https://github.com/Texarkanine/jekyll-highlight-cards/issues/19)) ([031a996](https://github.com/Texarkanine/jekyll-highlight-cards/commit/031a99634fbdd06741c5f2fcf6f9d098f23173c2))
* **deps-dev:** bump rubocop in the dev-deps-minor-patch group ([031a996](https://github.com/Texarkanine/jekyll-highlight-cards/commit/031a99634fbdd06741c5f2fcf6f9d098f23173c2))

## [1.1.0](https://github.com/Texarkanine/jekyll-highlight-cards/compare/v1.0.1...v1.1.0) (2025-12-20)


### Features

* split SCSS into structure and colors for flexible customization ([#17](https://github.com/Texarkanine/jekyll-highlight-cards/issues/17)) ([aa7271d](https://github.com/Texarkanine/jekyll-highlight-cards/commit/aa7271deeb4666f0ba41ecf389b876a3de479d03))


### Bug Fixes

* **build:** Do not include unnecessary files in the gem ([aa7271d](https://github.com/Texarkanine/jekyll-highlight-cards/commit/aa7271deeb4666f0ba41ecf389b876a3de479d03))

## [1.0.1](https://github.com/Texarkanine/jekyll-highlight-cards/compare/v1.0.0...v1.0.1) (2025-12-12)


### Bug Fixes

* **docs:** update gemspec description for rubygems.org ([8066854](https://github.com/Texarkanine/jekyll-highlight-cards/commit/80668542849e947459dab2e2a8b6e629d6984458))
* **polaroid:** "height: auto;" was missing so images got distorted on narrow screens ([#15](https://github.com/Texarkanine/jekyll-highlight-cards/issues/15)) ([c2a8165](https://github.com/Texarkanine/jekyll-highlight-cards/commit/c2a81658213ae84231287bc04cdf67309dc36d77))

## [1.0.0](https://github.com/Texarkanine/jekyll-highlight-cards/compare/v0.3.1...v1.0.0) (2025-12-09)


### Features

* **linkcard:** strip trailing slash from display urls ([7b2e3fb](https://github.com/Texarkanine/jekyll-highlight-cards/commit/7b2e3fb0645d6e927da55746711fed0d24147d8a))
* **polaroid:** add image_link parameter to override image href ([#11](https://github.com/Texarkanine/jekyll-highlight-cards/issues/11)) ([7b2e3fb](https://github.com/Texarkanine/jekyll-highlight-cards/commit/7b2e3fb0645d6e927da55746711fed0d24147d8a))


### Bug Fixes

* **deps-dev:** update rubocop-rspec requirement from ~&gt; 2.20 to ~&gt; 3.8 ([#13](https://github.com/Texarkanine/jekyll-highlight-cards/issues/13)) ([08e4a40](https://github.com/Texarkanine/jekyll-highlight-cards/commit/08e4a40c3463d43fc5eab9a4f4f04d335f34182c))
* **docs:** mention image_link in README ([50450a4](https://github.com/Texarkanine/jekyll-highlight-cards/commit/50450a4b20b4e5fd6ce6f0498bf208016903eb5d))
* **linkcard:** padding-bottom -&gt; 1.5 so archive doesn't overlap with link url ([7b2e3fb](https://github.com/Texarkanine/jekyll-highlight-cards/commit/7b2e3fb0645d6e927da55746711fed0d24147d8a))

## [0.3.1](https://github.com/Texarkanine/jekyll-highlight-cards/compare/v0.3.0...v0.3.1) (2025-12-08)


### Bug Fixes

* CSS was not automatically loaded when plugin was added to a site ([#9](https://github.com/Texarkanine/jekyll-highlight-cards/issues/9)) ([2183771](https://github.com/Texarkanine/jekyll-highlight-cards/commit/21837712ea9d47d61495c082dfc6a1d99c7dcac2))

## [0.3.0](https://github.com/Texarkanine/jekyll-highlight-cards/compare/v0.2.3...v0.3.0) (2025-12-08)


### Features

* **polaroid:** Wrap Polaroids in a container to allow block or inline-block display ([#7](https://github.com/Texarkanine/jekyll-highlight-cards/issues/7)) ([9904795](https://github.com/Texarkanine/jekyll-highlight-cards/commit/990479582798b0741472e8555da09221c6cdd2e9))

## [0.2.3](https://github.com/Texarkanine/jekyll-highlight-cards/compare/v0.2.2...v0.2.3) (2025-12-08)


### Bug Fixes

* **ci:** bot name ([f440e8e](https://github.com/Texarkanine/jekyll-highlight-cards/commit/f440e8e50f514e7905185849c12dd8dba0f579e4))
* **ci:** Bump Gemfile.lock in release-please PRs ([daa500f](https://github.com/Texarkanine/jekyll-highlight-cards/commit/daa500f0464504349c0e7daffc76a2d6ac8c3451))
* **ci:** Decorate commits properly when updating Gemfile.lock ([a2d17c4](https://github.com/Texarkanine/jekyll-highlight-cards/commit/a2d17c49e4857b548f2fea050581d671757e0afb))
* **ci:** Need to point rp at version-file ([17ad648](https://github.com/Texarkanine/jekyll-highlight-cards/commit/17ad648778f73ef27c0c0c122259276aed978197))
* **deps:** re-lock Gemfile? ([8988d60](https://github.com/Texarkanine/jekyll-highlight-cards/commit/8988d609a050d8b4f46007f7407df5c9c3be2b57))

## [0.2.2](https://github.com/Texarkanine/jekyll-highlight-cards/compare/v0.2.1...v0.2.2) (2025-12-08)


### Bug Fixes

* **ci:** something up w/ trusted publishing, make deployment env explicit...? ([f391a7e](https://github.com/Texarkanine/jekyll-highlight-cards/commit/f391a7e341730f80b7bbf1db21212c1c9511c4a6))

## [0.2.1](https://github.com/Texarkanine/jekyll-highlight-cards/compare/v0.2.0...v0.2.1) (2025-12-08)


### Bug Fixes

* **ci:** tests run w/ rspec directly, not rake ([e14f8ed](https://github.com/Texarkanine/jekyll-highlight-cards/commit/e14f8edb4e41e165c516970eddbfa6adba3d5832))

## [0.2.0](https://github.com/Texarkanine/jekyll-highlight-cards/compare/v0.1.0...v0.2.0) (2025-12-08)


### Features

* Add RubyGems trusted publishing to release workflow ([#2](https://github.com/Texarkanine/jekyll-highlight-cards/issues/2)) ([905bd50](https://github.com/Texarkanine/jekyll-highlight-cards/commit/905bd50a11b788b3948b6ee2d995c8c1118060f1))


### Bug Fixes

* **ci:** Add release-please-manifest.json ([30719ab](https://github.com/Texarkanine/jekyll-highlight-cards/commit/30719abdfb5964d55d26780ce9771c110d44f5cd))
* **ci:** leave all rp config to the JSON file ([47ca188](https://github.com/Texarkanine/jekyll-highlight-cards/commit/47ca1881c35e9946caa6e4deeee836f547c367f4))
* **ci:** separate Release-creation from gem publishing ([07114f9](https://github.com/Texarkanine/jekyll-highlight-cards/commit/07114f9e286f09c74812078b5b1f132257ab7b91))
