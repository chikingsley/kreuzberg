#!/usr/bin/env bash
#   $1: Package version (required)

set -euo pipefail

if [[ $# -lt 1 ]]; then
	echo "Usage: $0 <version>" >&2
	exit 1
fi

VERSION="$1"
DRY_RUN="${DRY_RUN:-false}"
PACKAGE_NAME="kreuzberg/kreuzberg"
PACKAGIST_API_TOKEN="${PACKAGIST_API_TOKEN:-}"

echo "::group::Publishing to Packagist"
echo "Package: ${PACKAGE_NAME}"
echo "Version: ${VERSION}"
echo "Dry run: ${DRY_RUN}"

if [[ "$DRY_RUN" == "true" ]]; then
	echo "::notice::Dry run mode - skipping Packagist update"
	echo "::endgroup::"
	exit 0
fi

# Trigger Packagist update using API token if available
if [[ -n "$PACKAGIST_API_TOKEN" ]]; then
	echo "::notice::Triggering Packagist update via API..."
	UPDATE_RESPONSE=$(curl \
		--silent \
		--show-error \
		--retry 3 \
		--retry-delay 5 \
		--request POST \
		"https://packagist.org/api/update-package?username=kreuzberg-dev&apiToken=${PACKAGIST_API_TOKEN}" \
		--data "{\"repository\": {\"url\": \"https://github.com/kreuzberg-dev/kreuzberg\"}}" \
		--header "Content-Type: application/json" 2>&1 || echo '{"status":"error"}')

	if echo "$UPDATE_RESPONSE" | jq -e '.status == "success"' >/dev/null 2>&1; then
		echo "::notice::✓ Packagist update triggered successfully"
	else
		echo "::warning::Failed to trigger Packagist update via API, falling back to webhook"
	fi
fi

echo "Waiting 30 seconds for package update..."
sleep 30

MAX_ATTEMPTS=12
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
	echo "Checking Packagist (attempt ${ATTEMPT}/${MAX_ATTEMPTS})..."

	RESPONSE=$(curl \
		--silent \
		--show-error \
		--retry 3 \
		--retry-delay 5 \
		"https://repo.packagist.org/p2/${PACKAGE_NAME}.json" 2>/dev/null || echo "{}")

	if echo "$RESPONSE" | jq -e ".packages[\"${PACKAGE_NAME}\"] | any(.version == \"${VERSION}\")" >/dev/null 2>&1; then
		echo "::notice::✓ Package ${PACKAGE_NAME}:${VERSION} is now available on Packagist"
		echo "::notice::View at: https://packagist.org/packages/${PACKAGE_NAME}#${VERSION}"
		echo "::endgroup::"
		exit 0
	fi

	if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
		echo "Version not found yet, waiting 10 seconds..."
		sleep 10
	fi

	ATTEMPT=$((ATTEMPT + 1))
done

echo "::warning::Package version not found on Packagist after ${MAX_ATTEMPTS} attempts"
echo "::warning::This may be a timing issue. Check Packagist manually:"
echo "::warning::  https://packagist.org/packages/${PACKAGE_NAME}"
echo "::warning::The package should appear once the GitHub webhook is processed."

echo "::endgroup::"
exit 0
