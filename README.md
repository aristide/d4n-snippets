# d4n-snippets

Code examples and reusable snippets for the **JupyterLab Code Loader** extension, maintained by the Data4Now team.

## Overview

This repository provides ready-to-use notebooks, scripts, and code snippets organized by domain. Content is served through the [JupyterLab Code Loader](https://github.com/aristide/d4n-snippets) sidebar panel, with multi-language support.

**Languages:** English, French

## Domains

### MinIO Object Storage

Python and Bash examples for interacting with MinIO S3-compatible object storage.

#### Code examples

| File | Type | Difficulty | Description |
|------|------|------------|-------------|
| `list_buckets_and_files.ipynb` | Notebook | Beginner | Connect to MinIO using environment variables and list all buckets and their contents |
| `csv_parquet_aggregation.ipynb` | Notebook | Intermediate | Read CSV/Parquet directly from MinIO into DataFrames (no download), aggregate, and save results as Parquet to another bucket |
| `ad_user_group_policy.sh` | Script | Intermediate | Add Active Directory users/groups to MinIO and attach IAM policies using the `mc` CLI |

#### Snippet collections

| File | Snippets | Description |
|------|----------|-------------|
| `minio_client_basics.json` | 6 | MinIO Python client: imports, credentials, create client, list buckets/objects |
| `s3fs_dataframe_operations.json` | 7 | S3FS + pandas: read CSV/Parquet, aggregate, save Parquet, full pipeline |
| `ad_policy_commands.json` | 13 | `mc` CLI commands: alias setup, policy CRUD, attach/detach user/group, LDAP lookup |

## Repository structure

```
d4n-snippets/
├── registry.json              # Auto-generated master index
├── domains/
│   └── minio/
│       ├── manifest.yaml      # Domain metadata and content list
│       ├── code/
│       │   ├── en/            # English code examples
│       │   └── fr/            # French code examples
│       └── snippets/
│           ├── en/            # English snippets
│           └── fr/            # French snippets
├── i18n/
│   ├── en.json                # English UI labels
│   └── fr.json                # French UI labels
└── meta/
    └── CONTRIBUTING.md
```

## Environment variables

Most examples expect these environment variables to be set:

| Variable | Description |
|----------|-------------|
| `MINIO_ENDPOINT` | MinIO server address (e.g. `minio.example.com:9000`) |
| `MINIO_ACCESS_KEY` | Access key (username) |
| `MINIO_SECRET_KEY` | Secret key (password) |
| `MINIO_SECURE` | `true` for HTTPS, `false` for HTTP (default) |

## Contributing

See [meta/CONTRIBUTING.md](meta/CONTRIBUTING.md) for guidelines on adding examples and translations.
