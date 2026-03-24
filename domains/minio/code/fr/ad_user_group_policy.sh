#!/usr/bin/env bash
# ============================================================================
# MinIO — Ajouter des utilisateurs/groupes Active Directory et leur attacher
#          des politiques d'accès (policies)
# ============================================================================
#
# Ce script montre comment utiliser l'outil en ligne de commande `mc`
# (MinIO Client) pour :
#
#   1. Configurer un alias (connexion) vers votre serveur MinIO
#   2. Activer l'intégration LDAP/Active Directory
#   3. Rechercher des utilisateurs et groupes AD
#   4. Créer ou utiliser des politiques IAM existantes
#   5. Attacher des politiques à des utilisateurs et groupes AD
#   6. Vérifier les politiques attachées
#
# PRÉREQUIS :
#   - `mc` CLI installé (https://min.io/docs/minio/linux/reference/minio-mc.html)
#   - Serveur MinIO configuré avec un fournisseur d'identité LDAP/Active Directory
#   - Identifiants administrateur pour le serveur MinIO
#
# VARIABLES D'ENVIRONNEMENT (à définir avant d'exécuter) :
#   MINIO_ENDPOINT    — adresse du serveur MinIO (ex. https://minio.example.com)
#   MINIO_ACCESS_KEY  — clé d'accès administrateur
#   MINIO_SECRET_KEY  — clé secrète administrateur
#   MINIO_ALIAS       — nom d'alias à utiliser   (par défaut : myminio)
#
# ============================================================================

set -euo pipefail  # Arrêter en cas d'erreur, variable non définie ou échec de pipe

# ---------------------------------------------------------------------------
# ÉTAPE 1 — Lire les variables d'environnement
# ---------------------------------------------------------------------------
# On lit les paramètres de connexion depuis les variables d'environnement
# pour que les mots de passe et clés n'apparaissent jamais directement
# dans le script.

ALIAS="${MINIO_ALIAS:-myminio}"            # nom d'alias par défaut si non défini
ENDPOINT="${MINIO_ENDPOINT}"               # obligatoire — le script échoue si absent
ACCESS_KEY="${MINIO_ACCESS_KEY}"           # obligatoire
SECRET_KEY="${MINIO_SECRET_KEY}"           # obligatoire

echo "=== Gestion des politiques utilisateurs/groupes AD dans MinIO ==="
echo "Point d'accès : ${ENDPOINT}"
echo "Alias         : ${ALIAS}"
echo ""

# ---------------------------------------------------------------------------
# ÉTAPE 2 — Créer ou mettre à jour l'alias MinIO
# ---------------------------------------------------------------------------
# Un alias est un profil de connexion enregistré. Il stocke le point d'accès,
# la clé d'accès et la clé secrète sous un nom court pour ne pas les répéter.

echo ">>> Configuration de l'alias '${ALIAS}'..."
mc alias set "${ALIAS}" "${ENDPOINT}" "${ACCESS_KEY}" "${SECRET_KEY}"
echo ""

# ---------------------------------------------------------------------------
# ÉTAPE 3 — Rechercher des utilisateurs et groupes Active Directory
# ---------------------------------------------------------------------------
# Avant d'attacher des politiques, vérifions que MinIO peut voir les entités AD.
# Les commandes `mc idp ldap` interrogent l'annuaire LDAP/AD configuré.

# Rechercher un utilisateur AD par son nom de connexion (sAMAccountName ou UPN)
# Remplacez "jdoe" par le nom d'utilisateur réel que vous souhaitez rechercher.
AD_USER="jdoe"

echo ">>> Recherche de l'utilisateur AD '${AD_USER}'..."
mc idp ldap policy entities "${ALIAS}" --user "uid=${AD_USER},dc=example,dc=com" || \
    echo "   (Utilisateur non trouvé ou LDAP non configuré — ajustez le DN selon votre annuaire)"
echo ""

# Rechercher un groupe AD par son nom distinctif (DN)
# Remplacez par le DN réel du groupe dans votre Active Directory.
AD_GROUP="cn=data-analysts,ou=groups,dc=example,dc=com"

echo ">>> Recherche du groupe AD '${AD_GROUP}'..."
mc idp ldap policy entities "${ALIAS}" --group "${AD_GROUP}" || \
    echo "   (Groupe non trouvé ou LDAP non configuré — ajustez le DN selon votre annuaire)"
echo ""

# ---------------------------------------------------------------------------
# ÉTAPE 4 — Lister les politiques IAM disponibles
# ---------------------------------------------------------------------------
# MinIO est livré avec des politiques intégrées et vous pouvez aussi créer
# des politiques personnalisées. Voyons ce qui est disponible.

echo ">>> Liste de toutes les politiques IAM sur '${ALIAS}'..."
mc admin policy list "${ALIAS}"
echo ""

# ---------------------------------------------------------------------------
# ÉTAPE 5 — Créer une politique personnalisée (optionnel)
# ---------------------------------------------------------------------------
# Si les politiques intégrées (readonly, readwrite, diagnostics, writeonly)
# ne suffisent pas, vous pouvez en créer une à partir d'un fichier JSON.
#
# Ci-dessous, nous créons une politique qui donne un accès en lecture seule
# à un bucket spécifique. Le JSON suit le même format que les politiques
# IAM d'AWS.

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

echo ">>> Création de la politique personnalisée '${POLICY_NAME}'..."
mc admin policy create "${ALIAS}" "${POLICY_NAME}" "${POLICY_FILE}"
echo "   Politique '${POLICY_NAME}' créée."
echo ""

# ---------------------------------------------------------------------------
# ÉTAPE 6 — Attacher une politique à un utilisateur AD
# ---------------------------------------------------------------------------
# Cela accorde la politique IAM spécifiée à un seul utilisateur Active Directory.
# L'utilisateur est identifié par son nom distinctif LDAP (DN).

echo ">>> Attachement de la politique '${POLICY_NAME}' à l'utilisateur AD '${AD_USER}'..."
mc admin policy attach "${ALIAS}" "${POLICY_NAME}" \
    --user "uid=${AD_USER},dc=example,dc=com"
echo "   Terminé."
echo ""

# ---------------------------------------------------------------------------
# ÉTAPE 7 — Attacher une politique à un groupe AD
# ---------------------------------------------------------------------------
# Cela accorde la politique à TOUS les membres du groupe Active Directory.
# Tout utilisateur appartenant à ce groupe héritera de la politique.

echo ">>> Attachement de la politique 'readwrite' au groupe AD '${AD_GROUP}'..."
mc admin policy attach "${ALIAS}" "readwrite" \
    --group "${AD_GROUP}"
echo "   Terminé."
echo ""

# ---------------------------------------------------------------------------
# ÉTAPE 8 — Vérifier les politiques attachées
# ---------------------------------------------------------------------------
# Lister toutes les associations politique-entité pour confirmer que tout
# est correct.

echo ">>> Vérification des politiques attachées..."
echo ""

echo "-- Politiques attachées à l'utilisateur '${AD_USER}' :"
mc admin policy entities "${ALIAS}" --user "uid=${AD_USER},dc=example,dc=com"
echo ""

echo "-- Politiques attachées au groupe '${AD_GROUP}' :"
mc admin policy entities "${ALIAS}" --group "${AD_GROUP}"
echo ""

# ---------------------------------------------------------------------------
# ÉTAPE 9 — Détacher une politique (annulation — montré à titre de référence)
# ---------------------------------------------------------------------------
# Pour retirer une politique d'un utilisateur ou groupe, utilisez "detach"
# au lieu de "attach". Décommentez les lignes ci-dessous si vous devez
# révoquer un accès.

# mc admin policy detach "${ALIAS}" "${POLICY_NAME}" \
#     --user "uid=${AD_USER},dc=example,dc=com"

# mc admin policy detach "${ALIAS}" "readwrite" \
#     --group "${AD_GROUP}"

echo "=== Terminé ! ==="
