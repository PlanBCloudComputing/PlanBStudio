#!/bin/sh
# check-authors.sh: pre-submission audit of commit authorship.
# Prints every distinct commit author with a count, then fails (exit 1) if any commit
# author, committer or message mentions Claude / Anthropic / Co-Authored-By.
# Usage:  sh scripts/check-authors.sh

echo "Commit authors (count, name <email>):"
git log --all --format='%an <%ae>' | sort | uniq -c | sort -rn

echo
echo "Committers (count, name <email>):"
git log --all --format='%cn <%ce>' | sort | uniq -c | sort -rn

echo
BAD=$(git log --all --format='%H %an <%ae> | %cn <%ce>%n%B' | grep -Ei 'claude|anthropic|co-authored-by|generated with')
if [ -n "$BAD" ]; then
  echo "FAIL: found Claude/Anthropic/Co-Authored-By/Generated-with references in history:" >&2
  echo "$BAD" >&2
  exit 1
fi

echo "OK: no Claude/Anthropic attribution found. Confirm the authors above are only Alvi, Katie and Steven."
exit 0
