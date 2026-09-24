#!/usr/bin/env bash
# epics.sh — validate epics and emit derived values
#
# Usage:
#   epics.sh validate  "OL-1, CL-2"   # exits 1 with message on bad input
#   epics.sh slug      "OL-1, CL-2"   # prints: ol-1-cl-2
#   epics.sh links     "OL-1, CL-2"   # prints: \href{...}{OL-1}, \href{...}{CL-2}
#
# The prefix→URL table is read from epic-prefixes.conf in the same directory.

set -euo pipefail

CONF="$(dirname "$0")/epic-prefixes.conf"

if [[ ! -f "$CONF" ]]; then
  echo "epics.sh: cannot find $CONF" >&2
  exit 1
fi

MODE="${1:-}"
EPICS_RAW="${2:-}"

# Build associative array from config (skip blank lines and comments)
declare -A URL_MAP
declare -a VALID_PREFIXES
while IFS= read -r line; do
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${line// }" ]] && continue
  prefix=$(echo "$line" | awk '{print $1}')
  url=$(echo "$line" | awk '{print $2}')
  URL_MAP["$prefix"]="$url"
  VALID_PREFIXES+=("$prefix")
done < "$CONF"

# Split the epics string on commas into an array
IFS=',' read -ra ITEMS <<< "$EPICS_RAW"

# Strip whitespace from each item
EPICS=()
for item in "${ITEMS[@]}"; do
  trimmed="${item#"${item%%[![:space:]]*}"}"
  trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
  EPICS+=("$trimmed")
done

# Build a regex of valid prefixes for validation
PREFIX_RE=$(IFS='|'; echo "${VALID_PREFIXES[*]}")

# Validate every epic
for epic in "${EPICS[@]}"; do
  if ! [[ "$epic" =~ ^(${PREFIX_RE})-[0-9]+$ ]]; then
    echo "epics.sh: invalid epic \"$epic\" — must be one of: ${VALID_PREFIXES[*]} followed by -nnnnn" >&2
    exit 1
  fi
done

case "$MODE" in
  validate)
    # already validated above; just exit 0
    ;;

  slug)
    # "OL-1, CL-2" → "ol-1-cl-2"
    result=""
    for epic in "${EPICS[@]}"; do
      lower=$(echo "$epic" | tr '[:upper:]' '[:lower:]')
      result="${result:+${result}-}${lower}"
    done
    echo "$result"
    ;;

  links)
    # Each epic → \href{url/number}{EPIC}, comma-separated
    result=""
    for epic in "${EPICS[@]}"; do
      prefix="${epic%%-*}"
      number="${epic#*-}"
      url="${URL_MAP[$prefix]}/${number}"
      link="\\href{${url}}{${epic}}"
      result="${result:+${result}, }${link}"
    done
    echo "$result"
    ;;

  *)
    echo "epics.sh: unknown mode \"$MODE\" (use: validate, slug, links)" >&2
    exit 1
    ;;
esac
