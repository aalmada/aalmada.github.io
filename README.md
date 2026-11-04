# Chirpy Starter

[![Gem Version](https://img.shields.io/gem/v/jekyll-theme-chirpy)][gem]&nbsp;
[![GitHub license](https://img.shields.io/github/license/cotes2020/chirpy-starter.svg?color=blue)][mit]

A minimal, ready-to-use template for creating a blog with the [**Chirpy**][chirpy] Jekyll theme. Get up and running in minutes with all critical files pre-configured.

## Why This Starter Exists

When installing Chirpy through [RubyGems.org][gem], Jekyll can only read a subset of theme files (`_data`, `_layouts`, `_includes`, `_sass`, `assets`) and limited `_config.yml` options from the gem. As a result, users cannot enjoy the full out-of-the-box experience that Chirpy offers.

To unlock all features, the following files must be present in your Jekyll site:

```shell
.
├── _config.yml
├── _plugins
├── _tabs
└── index.html
```

This starter bundles those files from the latest **Chirpy** release along with a [CD][CD] workflow, so you can start writing immediately.

## Usage

Check out the [theme's docs](https://github.com/cotes2020/jekyll-theme-chirpy/wiki).

### Post-deployment checks

The deployment workflow runs Lighthouse and Bing crawl checks after publishing.
These jobs are advisory (`continue-on-error: true`): the workflow can be green
even when either job fails. Inspect the individual jobs for audit results.

Lighthouse uses the Chrome binary installed by the workflow and a fixed debugging
port, and uploads JSON and HTML reports. Each category must score at least 80.
Browser startup and report-generation errors fail the audit step.

The Bing check requires the `BING_WEBMASTER_API_KEY` repository secret; without it,
the check logs a warning and skips. Crawl issues are reported as warnings, while
HTTP errors and invalid responses fail the check.

### Session recording consent

Microsoft Clarity is not requested until a visitor chooses **Allow Clarity**.
The choice is saved locally; **Session recording settings** below the footer lets
visitors change it. Declining after allowing revokes consent and reloads the page
to unload the recorder. Advertising storage stays denied. If browser storage is
unavailable, the UI explains that the choice cannot be saved.

This setting controls Clarity only; the existing Google Analytics integration is
unchanged. Homepage previews load the first two images eagerly with high fetch
priority so above-the-fold images do not wait for lazy loading.

For a smaller homepage card image, place an 800px-wide WebP named
`<original-name>-preview.webp` beside the original. The homepage uses it when
present; post images and social previews keep the original file.

## Contributing

This repository is automatically updated with new releases from the theme repository. If you encounter any issues or want to contribute to its improvement, please visit the [theme repository][chirpy] to provide feedback.

## License

This work is published under [MIT][mit] License.

[gem]: https://rubygems.org/gems/jekyll-theme-chirpy
[chirpy]: https://github.com/cotes2020/jekyll-theme-chirpy/
[CD]: https://en.wikipedia.org/wiki/Continuous_deployment
[mit]: https://github.com/cotes2020/chirpy-starter/blob/master/LICENSE
