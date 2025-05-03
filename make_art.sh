#!/bin/bash

# Script to create a GitHub contribution graph pattern for 2024
# Usage: ./script.sh <repo_path>
# Ensure the repo is initialized and linked to GitHub

# Check if repo path is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <repo_path>"
    exit 1
fi

REPO_PATH="$1"

# Change to the repository directory
cd "$REPO_PATH" || { echo "Failed to change to $REPO_PATH"; exit 1; }

# Ensure the repo is a git repository
if [ ! -d ".git" ]; then
    echo "Initializing git repository in $REPO_PATH"
    git init
    touch README.md
    echo "# GitHub Contribution Art" > README.md
    git add README.md
    git commit -m "Initial commit"
else
    echo "Clearing old commit history..."
    # Reset to the initial commit
    git checkout main || git checkout -b main
    git reset --hard $(git rev-list --max-parents=0 HEAD)  # Reset to initial commit
    # Remove art.txt if it exists
    if [ -f "art.txt" ]; then
        git rm art.txt
        git commit -m "Remove art.txt for fresh start"
    fi
    # Force push to GitHub to clear history
    git push --force origin main
fi

# File to modify for commits
FILE="art.txt"
touch "$FILE"
git add "$FILE"

# Function to make a commit on a specific date
make_commit() {
    local date="$1"
    local num_commits="$2"
    for ((i=0; i<num_commits; i++)); do
        echo "Commit $i on $date" >> "$FILE"
        git add "$FILE"
        GIT_AUTHOR_DATE="$date" GIT_COMMITTER_DATE="$date" git commit -m "Commit on $date" --quiet
    done
}

# 5x5 pixel patterns for each character (1 = commit, 0 = no commit)
# R
R=(
    "11110"
    "10001"
    "11110"
    "10001"
    "10001"
)

# E
E=(
    "11111"
    "10000"
    "11110"
    "10000"
    "11111"
)

# T
T=(
    "11111"
    "00100"
    "00100"
    "00100"
    "00100"
)

# A
A=(
    "01110"
    "10001"
    "11111"
    "10001"
    "10001"
)

# D
D=(
    "11110"
    "10001"
    "10001"
    "10001"
    "11110"
)

# C
C=(
    "01111"
    "10000"
    "10000"
    "10000"
    "01111"
)

# 3
THREE=(
    "11111"
    "00001"
    "11111"
    "00001"
    "11111"
)

# Heart (3x3)
HEART=(
    "01010"
    "11111"
    "01110"
)

# Start date: May 1, 2024 (Wednesday)
START_DATE="2023-05-01T12:00:00Z"

# Function to add days to a date
add_days() {
    local date="$1"
    local days="$2"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        date -j -f "%Y-%m-%dT%H:%M:%SZ" "$date" -v+"${days}"d "+%Y-%m-%dT%H:%M:%SZ"
    else
        # Linux: Convert to epoch, add days, then convert back
        local epoch
        epoch=$(date -d "${date%Z}" "+%s")  # Remove 'Z' and convert to epoch
        epoch=$((epoch + days * 86400))     # Add days in seconds (86400 seconds = 1 day)
        date -u -d "@$epoch" "+%Y-%m-%dT%H:%M:%SZ"  # Convert back to ISO format
    fi
}

# Current column offset (in days)
col_offset=0

# Function to apply a character pattern with corrected row mapping and 5-day downward shift
apply_pattern() {
    local -n pattern=$1
    local height=${#pattern[@]}
    local width=${#pattern[0]}

    # Determine the day of the week for START_DATE (0=Sun, 1=Mon, ..., 6=Sat)
    # May 1, 2024, is a Wednesday (day 3)
    local start_dow=3  # Wednesday

    # Additional shift: 5 days down
    local vertical_shift=5

    for ((row=0; row<height; row++)); do
        for ((col=0; col<width; col++)); do
            pixel=${pattern[$row]:$col:1}
            if [ "$pixel" -eq 1 ]; then
                # Map pattern row to graph row, adjusting for Monday-top layout and vertical shift
                # Graph rows: Mon=0, Tue=1, ..., Sun=6
                local graph_row=$(( (row + start_dow - 1 + vertical_shift) % 7 ))
                # Calculate total day offset: (graph_row) + (column * 7 days) + col_offset
                day_offset=$((graph_row + (col * 7) + col_offset))
                commit_date=$(add_days "$START_DATE" "$day_offset")
                make_commit "$commit_date" 1
            fi
        done
    done
    # Update column offset (width of character + 1 for gap)
    col_offset=$((col_offset + (width * 7) + 7))
}

# Apply each character pattern
apply_pattern R
apply_pattern E
apply_pattern T
apply_pattern A
apply_pattern R
apply_pattern D

# Apply heart pattern (adjust for 3x3 size)
apply_pattern HEART

# Apply C3 pattern
apply_pattern C
apply_pattern THREE

# Push to GitHub
echo "Pushing commits to GitHub..."
git push origin main

echo "Done! Check your GitHub contribution graph."
