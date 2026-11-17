#!/usr/bin/env bash
set -euo pipefail

# Bootstraps a GitHub Project v2 board, Status columns, repository link,
# needs-human label, and updates .agents/factory.config.json.
# Usage: ./.agents/setup-project.sh [project-title]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_PATH="$SCRIPT_DIR/factory.config.json"
TITLE="${1:-}"

if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "Error: Config not found at $CONFIG_PATH" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "Error: GitHub CLI (gh) is not installed." >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "Error: python3 is required for JSON parsing." >&2
  exit 1
fi

read -r OWNER REPO PROJECT_OWNER NEEDS_HUMAN_LABEL < <(
  python3 -c "
import json, sys
c = json.load(open('$CONFIG_PATH'))
print(c['github']['owner'], c['github']['repo'], c['github']['project_owner'], c['qa']['needs_human_label'])
"
)

if [[ "$OWNER" == your-* || "$REPO" == your-* || "$PROJECT_OWNER" == your-* ]]; then
  echo "Error: Please set github.owner, github.repo, and github.project_owner in .agents/factory.config.json first." >&2
  exit 1
fi

if [[ -z "$TITLE" ]]; then
  TITLE="$REPO Software Factory"
fi

echo "1. Creating GitHub Project v2 '$TITLE' under '$PROJECT_OWNER'..."
PROJECT_JSON="$(gh project create --owner "$PROJECT_OWNER" --title "$TITLE" --format json)"
PROJECT_NUMBER="$(echo "$PROJECT_JSON" | python3 -c "import sys, json; print(json.load(sys.stdin)['number'])")"
PROJECT_URL="$(echo "$PROJECT_JSON" | python3 -c "import sys, json; print(json.load(sys.stdin).get('url', ''))")"
echo "   Created Project #$PROJECT_NUMBER"

echo "2. Linking Project #$PROJECT_NUMBER to $OWNER/$REPO..."
gh project link "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --repo "$OWNER/$REPO"

echo "3. Configuring Status columns..."
FIELDS_JSON="$(gh project field-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json)"
STATUS_FIELD_ID="$(echo "$FIELDS_JSON" | python3 -c "
import sys, json
fields = json.load(sys.stdin)['fields']
for f in fields:
    if f.get('name') == 'Status':
        print(f['id'])
        break
")"

if [[ -z "$STATUS_FIELD_ID" ]]; then
  echo "Error: Could not find 'Status' field on Project #$PROJECT_NUMBER." >&2
  exit 1
fi

python3 -c "
import json
c = json.load(open('$CONFIG_PATH'))
cols = c['columns']
query = '''
mutation(\$fieldId: ID!, \$options: [ProjectV2SingleSelectFieldOptionInput!]!) {
  updateProjectV2Field(
    input: {
      fieldId: \$fieldId
      singleSelectOptions: \$options
    }
  ) {
    projectV2Field {
      ... on ProjectV2SingleSelectField {
        id
        name
        options { id name }
      }
    }
  }
}
'''
options = [
    {'name': cols['backlog'],      'color': 'GRAY',   'description': 'Ideas and unprioritized tasks'},
    {'name': cols['todo'],         'color': 'BLUE',   'description': 'Ready for factory-coder'},
    {'name': cols['in_progress'],  'color': 'YELLOW', 'description': 'Currently being implemented'},
    {'name': cols['deploy'],       'color': 'ORANGE', 'description': 'Merged and deploying'},
    {'name': cols['qa'],           'color': 'PURPLE', 'description': 'Under automated and browser QA'},
    {'name': cols['waiting_user'], 'color': 'RED',    'description': 'Needs human review or confirmation'},
    {'name': cols['done'],         'color': 'GREEN',  'description': 'Verified and completed'},
]
print(json.dumps({'query': query, 'variables': {'fieldId': '$STATUS_FIELD_ID', 'options': options}}))
" | gh api graphql --input - >/dev/null

echo "4. Creating label '$NEEDS_HUMAN_LABEL' in $OWNER/$REPO..."
gh label create "$NEEDS_HUMAN_LABEL" --repo "$OWNER/$REPO" --color "D93F0B" --description "Escalated by Software Factory" --force

echo "5. Updating $CONFIG_PATH with project_number = $PROJECT_NUMBER..."
python3 -c "
import json
p = '$CONFIG_PATH'
with open(p, 'r', encoding='utf-8') as f:
    c = json.load(f)
c['github']['project_number'] = int('$PROJECT_NUMBER')
with open(p, 'w', encoding='utf-8') as f:
    json.dump(c, f, indent=2)
    f.write('\n')
"

echo ""
echo "Done! Project #$PROJECT_NUMBER is ready: $PROJECT_URL"
