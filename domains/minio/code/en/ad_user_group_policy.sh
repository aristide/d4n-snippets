#!/usr/bin/env bash
# ============================================================================
# MinIO — Add Active Directory Users/Groups and Attach Policies
# ============================================================================
#
# This script shows how to use the `mc` (MinIO Client) command-line tool to:
#
#   1. Configure an alias (connection) to your MinIO server
#   2. Enable LDAP/Active Directory integration
#   3. Look up AD users and groups
#   4. Create or use built-in IAM policies
#   5. Attach policies to AD users and groups
#   6. Verify attached policies
#
# PREREQUISITES:
#   - `mc` CLI installed (https://min.io/docs/minio/linux/reference/minio-mc.html)
#   - MinIO server configured with LDAP/Active Directory identity provider
#   - Admin credentials for the MinIO server
#
# ENVIRONMENT VARIABLES (set these before running):
#   MINIO_ENDPOINT    — MinIO server address    (e.g. https://minio.example.com)
#   MINIO_ACCESS_KEY  — Admin access key
#   MINIO_SECRET_KEY  — Admin secret key
#   MINIO_ALIAS       — Alias name to use       (default: myminio)
#
# ============================================================================

set -euo pipefail  # Stop on errors, undefined variables, and pipe failures

# ---------------------------------------------------------------------------
# STEP 1 — Read environment variables
# ---------------------------------------------------------------------------
# We read connection settings from environment variables so that passwords
# and keys never appear directly in the script.

ALIAS="${MINIO_ALIAS:-myminio}"            # default alias name if not set
ENDPOINT="${MINIO_ENDPOINT}"               # required — script fails if missing
ACCESS_KEY="${MINIO_ACCESS_KEY}"           # required
SECRET_KEY="${MINIO_SECRET_KEY}"           # required

echo "=== MinIO AD User/Group Policy Management ==="
echo "Endpoint : ${ENDPOINT}"
echo "Alias    : ${ALIAS}"
echo ""

# ---------------------------------------------------------------------------
# STEP 2 — Create or update the MinIO alias
# ---------------------------------------------------------------------------
# An alias is a saved connection profile. It stores the endpoint, access key,
# and secret key under a short name so you don't have to repeat them.

echo ">>> Setting up alias '${ALIAS}'..."
mc alias set "${ALIAS}" "${ENDPOINT}" "${ACCESS_KEY}" "${SECRET_KEY}"
echo ""

# ---------------------------------------------------------------------------
# STEP 3 — Look up Active Directory users and groups
# ---------------------------------------------------------------------------
# Before attaching policies, let's verify that MinIO can see the AD entities.
# The `mc idp ldap` commands query the configured LDAP/AD directory.

# Search for an AD user by their login name (sAMAccountName or UPN)
# Replace "jdoe" with the actual username you want to look up.
AD_USER="jdoe"

echo ">>> Looking up AD user '${AD_USER}'..."
mc idp ldap policy entities "${ALIAS}" --user "uid=${AD_USER},dc=example,dc=com" || \
    echo "   (User not found or LDAP not configured — adjust the DN to your directory)"
echo ""

# Search for an AD group by its distinguished name (DN)
# Replace with the actual group DN from your Active Directory.
AD_GROUP="cn=data-analysts,ou=groups,dc=example,dc=com"

echo ">>> Looking up AD group '${AD_GROUP}'..."
mc idp ldap policy entities "${ALIAS}" --group "${AD_GROUP}" || \
    echo "   (Group not found or LDAP not configured — adjust the DN to your directory)"
echo ""

# ---------------------------------------------------------------------------
# STEP 4 — List available IAM policies
# ---------------------------------------------------------------------------
# MinIO ships with built-in policies and you can also create custom ones.
# Let's see what is available before attaching anything.

echo ">>> Listing all IAM policies on '${ALIAS}'..."
mc admin policy list "${ALIAS}"
echo ""

# ---------------------------------------------------------------------------
# STEP 5 — Create a custom policy (optional)
# ---------------------------------------------------------------------------
# If the built-in policies (readonly, readwrite, diagnostics, writeonly)
# are not enough, you can create a custom one from a JSON file.
#
# Below we create a policy that gives read-only access to a specific bucket.
# The policy JSON follows the same format as AWS IAM policies.

POLICY_NAME="analysts-readonly"
POLICY_FILE="/tmp/analysts-readonly-policy.json"

cat > "${POLICY_FILE}" <<'POLICY'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::analytics-data",
        "arn:aws:s3:::analytics-data/*"
      ]
    }
  ]
}
POLICY

echo ">>> Creating custom policy '${POLICY_NAME}'..."
mc admin policy create "${ALIAS}" "${POLICY_NAME}" "${POLICY_FILE}"
echo "   Policy '${POLICY_NAME}' created."
echo ""

# ---------------------------------------------------------------------------
# STEP 6 — Attach a policy to an AD user
# ---------------------------------------------------------------------------
# This grants the specified IAM policy to a single Active Directory user.
# The user is identified by their LDAP Distinguished Name (DN).

echo ">>> Attaching policy '${POLICY_NAME}' to AD user '${AD_USER}'..."
mc admin policy attach "${ALIAS}" "${POLICY_NAME}" \
    --user "uid=${AD_USER},dc=example,dc=com"
echo "   Done."
echo ""

# ---------------------------------------------------------------------------
# STEP 7 — Attach a policy to an AD group
# ---------------------------------------------------------------------------
# This grants the policy to ALL members of the Active Directory group.
# Any user who belongs to this group will inherit the policy.

echo ">>> Attaching policy 'readwrite' to AD group '${AD_GROUP}'..."
mc admin policy attach "${ALIAS}" "readwrite" \
    --group "${AD_GROUP}"
echo "   Done."
echo ""

# ---------------------------------------------------------------------------
# STEP 8 — Verify attached policies
# ---------------------------------------------------------------------------
# List all policy-entity mappings to confirm everything is correct.

echo ">>> Verifying policy attachments..."
echo ""

echo "-- Policies attached to user '${AD_USER}':"
mc admin policy entities "${ALIAS}" --user "uid=${AD_USER},dc=example,dc=com"
echo ""

echo "-- Policies attached to group '${AD_GROUP}':"
mc admin policy entities "${ALIAS}" --group "${AD_GROUP}"
echo ""

# ---------------------------------------------------------------------------
# STEP 9 — Detach a policy (undo — shown for reference)
# ---------------------------------------------------------------------------
# To remove a policy from a user or group, use "detach" instead of "attach".
# Uncomment the lines below if you need to revoke access.

# mc admin policy detach "${ALIAS}" "${POLICY_NAME}" \
#     --user "uid=${AD_USER},dc=example,dc=com"

# mc admin policy detach "${ALIAS}" "readwrite" \
#     --group "${AD_GROUP}"

echo "=== All done! ==="
