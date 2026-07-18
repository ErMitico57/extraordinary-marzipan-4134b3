#!/bin/bash
set -e

QUERIES=(
    "best free online calculator tools 2024"
    "interactive astronomy quiz ideas"
    "daily horoscope generator widget"
    "moon phase calculator"
    "planetary alignment finder"
    "star sign compatibility tool"
    "random name generator for babies"
    "tip calculator split bill"
    "BMI calculator simple"
    "loan interest calculator"
)

LOG_FILE="logs/concept_generation.log"
PENDING_DIR="concepts/pending"
MAP_FILE="concepts/map.json"

# Initialize map array
MAP_ARRAY=()

# Function to log errors
log_error() {
    echo "[$(date)] ERROR: $1" >> "$LOG_FILE"
}

# Process each query
for idx in "${!QUERIES[@]}"; do
    query="${QUERIES[$idx]}"
    echo "Processing query: $query" >> "$LOG_FILE"
    
    # Perform web search
    search_result=$(oxylabs_web_search --query "$query" --count 5 2>>"$LOG_FILE") || {
        log_error "Failed to search for query: $query"
        continue
    }
    
    # Extract title and snippet from the first result
    # Assuming the JSON structure: { results: [ {title: "...", description: "..."}, ... ] }
    title=$(echo "$search_result" | jq -r '.results[0].title // ""')
    snippet=$(echo "$search_result" | jq -r '.results[0].description // ""')
    
    # If title is empty, try to get from the first result's title field differently
    if [ -z "$title" ]; then
        title=$(echo "$search_result" | jq -r '.results[0].title // ""' 2>/dev/null) || title=""
    fi
    if [ -z "$snippet" ]; then
        snippet=$(echo "$search_result" | jq -r '.results[0].snippet // ""' 2>/dev/null) || snippet=""
    fi
    
    # If still empty, use a generic description
    if [ -z "$title" ] && [ -z "$snippet" ]; then
        title="$query"
        snippet="A tool or calculator related to $query."
    fi
    
    # Create a description: combine title and snippet, limit to 200 chars
    description="$title: $snippet"
    # Trim to 200 characters
    if [ ${#description} -gt 200 ]; then
        description="${description:0:200}..."
    fi
    
    # Create slug
    slug=$(echo "$query" | tr '[:upper:]' '[:lower:]' | tr -s ' ' '_' | sed 's/[^a-z0-9_]//g')
    # Ensure slug is not empty
    if [ -z "$slug" ]; then
        slug="concept_$((idx+1))"
    fi
    
    # File path
    file_path="${PENDING_DIR}/${slug}.txt"
    
    # Write the file
    {
        echo "Concept: $title"
        echo ""
        echo "Description:"
        echo "$description"
    } > "$file_path" 2>>"$LOG_FILE" || {
        log_error "Failed to write file for query: $query"
        continue
    }
    
    # Get preview (first 100 characters of description)
    preview=$(echo "$description" | cut -c1-100)
    if [ ${#description} -gt 100 ]; then
        preview="${preview}..."
    fi
    
    # Add to map array
    MAP_ARRAY+=( {"index": $((idx+1)), "file": "${slug}.txt", "preview": "$preview"} )
done

# Write map.json
echo "[" > "$MAP_FILE"
for i in "${!MAP_ARRAY[@]}"; do
    if [ $i -gt 0 ]; then
        echo "," >> "$MAP_FILE"
    fi
    echo "${MAP_ARRAY[$i]}" >> "$MAP_FILE"
done
echo "]" >> "$MAP_FILE"

echo "Processed ${#QUERIES[@]} queries. Created ${#MAP_ARRAY[@]} successful." >> "$LOG_FILE"
