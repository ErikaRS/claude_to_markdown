# Claude to Markdown Converter

A simple bash script to convert Anthropic Claude chat backups to Markdown files.

## 🤖 Created With Claude Code

This entire project was "vibe coded" with Claude Code! The script was written in a single Claude session without any manual coding.

## Usage

```bash
./claude_to_md.sh <claude_backup_directory>
```

The script will:
1. Process the `conversations.json` file in the backup directory
2. Create markdown files for each conversation 
3. Output files to `tmp_md_<original_directory_name>/`

## Example

```bash
./claude_to_md.sh ~/Downloads/claude-2025-04-07
```

This creates markdown files in `tmp_md_claude-2025-04-07/` with:
- Conversation title as markdown heading
- Date of conversation
- Human/Claude exchanges properly formatted
- Any file attachments listed

## Requirements

- `jq` for JSON processing
- Bash shell

## License

Feel free to use and modify as needed!