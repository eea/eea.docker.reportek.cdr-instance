# Zope 5 w/ CDR Add-ons ready to run Docker image

Downstream, application-specific Docker Hardened Image (DHI) for the Reportek CDR environment.

## Architecture Context

This image natively subclasses [eeacms/reportek-base-dr:z5](https://hub.docker.com/r/eeacms/reportek-base-dr) leveraging the pre-compiled Zope 5 infrastructure to cleanly enforce specific application-layer topologies:
1. **ZCML Overlays:** Injects a custom `site.zcml` mapping `<include package="Products.Reportek" file="views.cdr.zcml" />` explicitly targeting CDR views.
2. **Environment Globals:** Enforces metadata variables specifically tuned to the CDR footprint.

## Environment Variables

Aside from the standard Zope Waitress runtime variables handled by the Base image (`ZEO_ADDRESS`, `ZOPE_THREADS`, etc.), this CDR overlay explicitly overrides the following globals by default inside the `Dockerfile`:

| Variable | Default | Description |
|----------|---------|-------------|
| `REPORTEK_DEPLOYMENT` | `CDR` | Context marker identifying the environment |
| `DATADICTIONARY_SCHEMAS_URL` | `http://dd.eionet.europa.eu/api/schemas/forObligation` | Target URL for EIONET DD validation |
| `UNS_NOTIFICATIONS` | `on` | Explicitly enables Unified Notification System hooks |

## Execution

Because this image identically inherits the `docker-entrypoint.sh` definitions from the Base image, standard commands gracefully resolve downward:

```bash
# Start Waitress natively mapped to the CDR overlays
docker run -p 8080:8080 eeacms/reportek-cdr:z5 start
```

## Copyright and license

The Initial Owner of the Original Code is European Environment Agency (EEA).
All Rights Reserved.

The Original Code is free software;
you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation;
either version 2 of the License, or (at your option) any later
version.

## Funding

[European Environment Agency (EU)](http://eea.europa.eu)
