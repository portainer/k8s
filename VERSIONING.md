# Helm Chart Versioning

## Scheme

The chart version directly encodes the Portainer release it targets:

```
Portainer 2.39.1  →  Chart 239.1.0
           ↑ ↑↑              ↑ ↑ ↑
           │ │└─────────────→┘ │ └─ chart patch (chart-only changes, resets to 0 on each Portainer release)
           │ └────────────────→┘
           └──── collapsed into the major version
```

The Portainer major and minor version numbers are concatenated to form the chart's major version (`2.39` → `239`). The Portainer patch version maps directly to the chart's minor version (`2.39.1` → `239.1`). The chart patch (`239.1.x`) increments independently for chart-only changes within that Portainer release and always resets to `0` when a new Portainer version is released.

## Examples

| Portainer version | Chart version | Reason for release |
|---|---|---|
| 2.39.0 | 239.0.0 | Initial chart release for Portainer 2.39 LTS |
| 2.39.0 | 239.0.1 | Chart bug fix, no change to Portainer version |
| 2.39.0 | 239.0.2 | New Helm feature added (e.g. new values option) |
| 2.39.1 | 239.1.0 | Portainer patch release — chart patch resets to 0 |
| 2.39.1 | 239.1.1 | Chart bug fix against Portainer 2.39.1 |
| 2.45.0 | 245.0.0 | New Portainer LTS — major version bumps, chart patch resets to 0 |

## Rationale

Portainer follows an LTS release cadence. A given chart version is always tied to a specific Portainer release, and it should be immediately clear from the chart version number which Portainer version you are deploying — without needing to consult a separate compatibility matrix.

The chart patch increment (`239.0.1`, `239.0.2`, ...) exists because the chart may need updates between Portainer releases: fixing a Helm bug, adding support for a new configuration option, or improving CI. These are chart-side changes that do not alter the Portainer version being deployed. The chart patch always resets to `0` whenever a new Portainer version is released, whether that is a patch release (`2.39.0` → `2.39.1`) or a new LTS (`2.39.x` → `2.45.0`).

## Semver trade-off

This scheme is not conventional semver. Strict semver tooling (Helm's dependency resolver, Renovate, Dependabot) interprets a major version bump as a breaking API change. Under this scheme, going from `239.0.x` to `245.0.0` is a new Portainer LTS — not a breaking change in the semver sense.

This is a deliberate trade-off, consistent with how other large projects version their Helm charts (Bitnami charts follow a similar approach). The benefit — an unambiguous, human-readable link between chart version and product version — outweighs the cost of diverging from semver conventions. Automated tooling should be configured to treat major version bumps as routine upgrades rather than blocking changes.
