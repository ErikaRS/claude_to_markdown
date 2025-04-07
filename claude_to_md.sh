#!/bin/bash

# Check if input directory is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <claude_backup_directory>"
    exit 1
fi

SOURCE_DIR="$1"
DIR_NAME=$(basename "$SOURCE_DIR")
OUTPUT_DIR="tmp_md_${DIR_NAME}"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory does not exist"
    exit 1
fi

# Check if conversations.json exists
if [ ! -f "$SOURCE_DIR/conversations.json" ]; then
    echo "Error: conversations.json not found in the source directory"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"
echo "Created output directory: $OUTPUT_DIR"

# Process conversations
echo "Processing conversations from $SOURCE_DIR/conversations.json"

# Convert conversations.json to markdown files
jq -c '.[]' "$SOURCE_DIR/conversations.json" | while read -r conversation; do
    # Extract conversation details
    uuid=$(echo "$conversation" | jq -r '.uuid')
    name=$(echo "$conversation" | jq -r '.name')
    created_at=$(echo "$conversation" | jq -r '.created_at' | cut -d'T' -f1)
    
    # Sanitize the filename
    safe_name=$(echo "$name" | sed 's/[^a-zA-Z0-9_ -]//g' | tr ' ' '_')
    filename="${OUTPUT_DIR}/${created_at}_${safe_name}.md"
    
    # Start the markdown file with the title
    echo "# ${name}" > "$filename"
    echo "" >> "$filename"
    echo "Date: ${created_at}" >> "$filename"
    echo "" >> "$filename"
    
    # Process each message in the conversation
    echo "$conversation" | jq -c '.chat_messages[]' | while read -r message; do
        sender=$(echo "$message" | jq -r '.sender')
        text=$(echo "$message" | jq -r '.text')
        
        # Handle message based on sender
        if [ "$sender" = "human" ]; then
            echo "## Human:" >> "$filename"
        else
            echo "## Claude:" >> "$filename"
        fi
        
        echo "" >> "$filename"
        echo "$text" >> "$filename"
        echo "" >> "$filename"
        
        # Check if there are attachments or files
        has_files=$(echo "$message" | jq '.files | length > 0')
        if [ "$has_files" = "true" ]; then
            echo "### Attachments:" >> "$filename"
            echo "" >> "$filename"
            
            echo "$message" | jq -c '.files[]' | while read -r file; do
                file_name=$(echo "$file" | jq -r '.file_name')
                echo "- ${file_name}" >> "$filename"
            done
            
            echo "" >> "$filename"
        fi
    done
    
    echo "Created: $filename"
done

echo "Conversion complete. Markdown files are in $OUTPUT_DIR/"