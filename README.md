# Livebox-Scanner

Small set of scripts to scan Livebox routers in certain IP ranges, and try to exploit APIs default credentials to retrieve PSK password and DDNS registration data. The recovered data is saved to a SQLite DB, ingested by logstash, and displayed in several Kibana dashboards.

- kibana directory: Exported objects from Kibana (dashboards, index patterns...) and template modifications needed by geodata to be plotted in a map visualization.
- databases: data recovered from the scans.
- logtash: Configuration file for the ingestion of the SQLite data.
- scanner: Bash scripts to scan IP ranges, recover information and save that information to a database.
