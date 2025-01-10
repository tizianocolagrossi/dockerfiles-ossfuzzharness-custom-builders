#! /home/tiziano/.pyenv/shims/python3
## from json extracted with llvm-cov export get the filenames and the lines touched
import json

# Load the JSON file
with open('./llvmcov.json', 'r') as f:
    coverage_data = json.load(f)

# Extract filenames and lines
touched_files = {}

for entry in coverage_data['data']:
    for file_data in entry['files']:
        filename = file_data['filename']
        touched_lines = []
        
        # Extract only the executed lines
        for segment in file_data['segments']:
            line_number = segment[0]
            execution_count = segment[2]
            if execution_count > 0:  # Only include executed lines
                touched_lines.append(line_number)
        
        # Store results if there are any executed lines
        if touched_lines:
            touched_files[filename] = touched_lines

# Write dictionary to a JSON file
with open('./coverage_out.json', "w") as json_file:
    json.dump(touched_files, json_file, indent=4)