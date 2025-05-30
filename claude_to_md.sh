#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

# Check if input directory is provided
if [[ "$#" -ne 1 ]]; then
    echo "Usage: $0 <claude_backup_directory>" >&2
    exit 1
fi

readonly SOURCE_DIR="$1"
readonly DIR_NAME=$(basename "$SOURCE_DIR")
readonly OUTPUT_DIR="tmp_md_${DIR_NAME}"

# Check if source directory exists
if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Error: Source directory does not exist" >&2
    exit 1
fi

# Check if conversations.json exists
if [[ ! -f "$SOURCE_DIR/conversations.json" ]]; then
    echo "Error: conversations.json not found in the source directory" >&2
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"
echo "Created output directory: $OUTPUT_DIR"

# Process conversations
echo "Processing conversations from $SOURCE_DIR/conversations.json"

# Convert conversations.json to markdown files
while IFS= read -r conversation; do
    # Extract conversation details
    uuid=$(echo "$conversation" | jq -r '.uuid')
    name=$(echo "$conversation" | jq -r '.name')
    created_at=$(echo "$conversation" | jq -r '.created_at' | cut -d'T' -f1)
    
    # Sanitize the filename
    safe_name=$(echo "$name" | sed 's/[^a-zA-Z0-9_ -]//g' | tr ' ' '_')
    filename="${OUTPUT_DIR}/${created_at}_${safe_name}.md"
    
    # Start the markdown file with the title
    {
        echo "# ${name}"
        echo ""
        echo "Date: ${created_at}"
        echo ""
    } > "$filename"
    
    # Process each message in the conversation
    while IFS= read -r message; do
        sender=$(echo "$message" | jq -r '.sender')
        text=$(echo "$message" | jq -r '.text')
        
        # Handle message based on sender
        {
            if [[ "$sender" = "human" ]]; then
                echo "## Human:"
            else
                echo "## Claude:"
            fi
            
            echo ""
            echo "$text"
            echo ""
        } >> "$filename"
        
        # Check if there are attachments or files
        has_files=$(echo "$message" | jq '.files | length > 0')
        if [[ "$has_files" = "true" ]]; then
            {
                echo "### Attachments:"
                echo ""
            } >> "$filename"
            
            while IFS= read -r file; do
                file_name=$(echo "$file" | jq -r '.file_name')
                echo "- ${file_name}" >> "$filename"
            done < <(echo "$message" | jq -c '.files[]')
            
            echo "" >> "$filename"
        fi
    done < <(echo "$conversation" | jq -c '.chat_messages[]')
    
    echo "Created: $filename"
done < <(jq -c '.[]' "$SOURCE_DIR/conversations.json")

echo "Conversion complete. Markdown files are in $OUTPUT_DIR/"