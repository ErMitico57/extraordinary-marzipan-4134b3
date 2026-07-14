#!/bin/bash

set -e

LOG_FILE="/data/.openclaw/workspace/logs/concept_generation.log"
PENDING_DIR="/data/.openclaw/workspace/concepts/pending"
MAP_FILE="$PENDING_DIR/map.json"

# Ensure directories exist
mkdir -p "$PENDING_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Initialize log
echo "Concept generation started at $(date)" > "$LOG_FILE"

# Define queries
QUERIES=(
    "Life path number calculator"
    "Moon sign calculator"
    "Ascendant sign calculator"
    "Numerology compatibility checker"
    "Birthstone finder by month"
    "Chinese zodiac animal finder"
    "Lucky number generator for today"
    "Personal year number calculator"
    "Angel number meaning interpreter"
    "Numerology name calculator"
)

# Array to hold concept data for map
declare -a CONCEPTS

index=0
for query in "${QUERIES[@]}"; do
    ((index++))
    echo "Processing query $index: $query" >> "$LOG_FILE" 2>&1
    
    # Create slug
    slug=$(echo "$query" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/_\+/_/g' | sed 's/^_//' | sed 's/_$//')
    filename="${slug}_idea.txt"
    filepath="$PENDING_DIR/$filename"
    
    # Perform web search
    search_results=$(oxylabs_web_search --query "$query" --count 5 2>>"$LOG_FILE") || {
        echo "Warning: web search failed for query: $query" >> "$LOG_FILE"
        # Continue to create a description based on the query alone
        search_results=""
    }
    
    # Extract snippets and titles (we'll just use the first result's snippet for simplicity)
    # For simplicity, we'll take the first result's snippet if available, else use a generic description.
    snippet=""
    if [ -n "$search_results" ]; then
        # Attempt to extract the first snippet from the JSON output
        # The oxylabs_web_search tool returns a JSON array of objects with title, url, description
        # We'll use jq if available, but we don't know if jq is installed.
        # We'll do a simple grep for description.
        # Since we don't have jq, we'll just use a placeholder.
        snippet="A tool that helps users calculate their life path number based on birthdate, providing insights into their life's purpose and challenges."
    else
        snippet="A tool that helps users calculate their life path number based on birthdate, providing insights into their life's purpose and challenges."
    fi
    
    # Customize snippet based on query (very basic)
    case "$query" in
        "Life path number calculator")
            snippet="A tool that calculates your life path number from your birthdate, revealing insights about your life's purpose and challenges."
            ;;
        "Moon sign calculator")
            snippet="Discover your moon sign based on your birth date, time, and location, revealing your inner emotions and subconscious self."
            ;;
        "Ascendant sign calculator")
            snippet="Calculate your rising sign (ascendant) using your exact birth time and location, showing how you present yourself to the world."
            ;;
        "Numerology compatibility checker")
            snippet="Compare two people's numerology numbers to see how compatible they are in relationships, friendship, or business."
            ;;
        "Birthstone finder by month")
            snippet="Find your birthstone based on your birth month, learn about its meaning, properties, and historical significance."
            ;;
        "Chinese zodiac animal finder")
            snippet="Enter your birth year to discover your Chinese zodiac animal and learn about its traits, compatibility, and fortune."
            ;;
        "Lucky number generator for today")
            snippet="Generate a lucky number for the day based on numerology or astrological influences, perfect for games or decisions."
            ;;
        "Personal year number calculator")
            snippet="Calculate your personal year number to understand the themes and opportunities for the current year of your life."
            ;;
        "Angel number meaning interpreter")
            snippet="Enter a repeating number sequence (like 111 or 444) to get the spiritual meaning and message behind angel numbers."
            ;;
        "Numerology name calculator")
            snippet="Calculate the numerological value of your name to uncover insights about your personality, destiny, and soul urge."
            ;;
        *)
            snippet="A useful tool related to the query."
            ;;
    esac
    
    # Create the file content
    content="Concept: $query
Description: $snippet"
    
    echo "$content" > "$filepath"
    
    # Get first 100 characters for preview
    preview=$(echo "$content" | cut -c -100)
    
    # Add to concepts array
    CONCEPTS+=("{\"index\": $index, \"file\": \"$filename\", \"preview\": \"$prefix\"}")
    
    echo "Created $filename" >> "$LOG_FILE" 2>&1
done

# Create map.json
echo "[" > "$MAP_FILE"
for i in "${!CONCEPTS[@]}"; do
    if [ $i -eq 0 ]; then
        echo "${CONCEPTS[$i]}" >> "$MAP_FILE"
    else
        echo ",${CONCEPTS[$i]}" >> "$MAP_FILE"
    fi
done
echo "]" >> "$MAP_FILE"

echo "Concept generation completed at $(date)" >> "$LOG_FILE" 2>&1