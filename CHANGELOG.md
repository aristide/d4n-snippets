# Changelog

All notable changes to this repository are documented in this file, organized by date.

## 2026-03-24

### Added

- **Repository scaffolding** — `registry.json`, `i18n/en.json`, `i18n/fr.json`, `meta/CONTRIBUTING.md`, `.gitignore`
- **MinIO domain** (`domains/minio/`) with `manifest.yaml`
- **Notebook: List Buckets and Files** (`list_buckets_and_files.ipynb`) — beginner notebook to connect to MinIO using environment variables and list all buckets and objects (EN + FR)
- **Notebook: CSV & Parquet Aggregation** (`csv_parquet_aggregation.ipynb`) — intermediate notebook to read CSV/Parquet directly from MinIO via `s3fs` (no download), perform `groupby` aggregations with pandas, and save results as Parquet to another bucket (EN + FR)
- **Script: AD User/Group Policy Management** (`ad_user_group_policy.sh`) — intermediate bash script to add Active Directory users/groups to MinIO and attach/detach IAM policies using the `mc` CLI (EN + FR)
- **Snippets: MinIO Python Client Basics** (`minio_client_basics.json`) — 6 snippets covering imports, env var credentials, client creation, listing buckets and objects (EN + FR)
- **Snippets: S3FS DataFrame Operations** (`s3fs_dataframe_operations.json`) — 7 snippets for reading CSV/Parquet from MinIO, aggregating with pandas, saving Parquet, and a full pipeline example (EN + FR)
- **Snippets: AD Policy Commands** (`ad_policy_commands.json`) — 13 `mc` CLI snippets for alias setup, policy CRUD, attach/detach to AD users/groups, and LDAP lookups (EN + FR)
