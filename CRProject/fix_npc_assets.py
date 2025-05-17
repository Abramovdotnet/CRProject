import os
import json
import re
import shutil

def fix_npc_assets(base_path):
    print(f"Starting script in base path: {base_path}")
    npc_folder_pattern = re.compile(r"^(npc|npv)(\\d+)\\.imageset$", re.IGNORECASE) # Make regex case-insensitive and catch npv
    corrected_count = 0
    processed_folders = 0

    if not os.path.isdir(base_path):
        print(f"Error: Base path {base_path} is not a directory or does not exist.")
        return

    for folder_name in os.listdir(base_path):
        processed_folders += 1
        current_folder_path = os.path.join(base_path, folder_name)
        if not os.path.isdir(current_folder_path):
            # print(f"Skipping non-directory: {folder_name}")
            continue

        original_folder_name_for_logging = folder_name
        # print(f"Processing folder: {folder_name}")

        match = npc_folder_pattern.match(folder_name)
        
        # Handle folder name correction (e.g., npv -> npc)
        if match and folder_name.lower().startswith("npv"):
            npc_id_from_match = match.group(2)
            new_folder_name = f"npc{npc_id_from_match}.imageset"
            if folder_name != new_folder_name:
                new_folder_path_for_rename = os.path.join(base_path, new_folder_name)
                try:
                    # Check if the target directory already exists (e.g. if npcXXX exists and npvXXX also exists)
                    if os.path.exists(new_folder_path_for_rename):
                        print(f"Warning: Target folder {new_folder_name} already exists. Skipping rename of {folder_name}.")
                        # Potentially add logic here to merge or decide which to keep, for now, skip.
                        continue 
                    os.rename(current_folder_path, new_folder_path_for_rename)
                    print(f"Renamed folder: {folder_name} -> {new_folder_name}")
                    folder_name = new_folder_name
                    current_folder_path = new_folder_path_for_rename
                    match = npc_folder_pattern.match(folder_name) # Re-match with the new name
                    corrected_count +=1
                except Exception as e:
                    print(f"Error renaming folder {original_folder_name_for_logging} to {new_folder_name}: {e}")
                    continue
        
        if not match:
            # print(f"Skipping folder not matching pattern 'npc<ID>.imageset' or 'npv<ID>.imageset': {original_folder_name_for_logging}")
            continue

        # Extract NPC ID from the potentially corrected folder name
        npc_id = match.group(2)
        expected_png_filename = f"npc{npc_id}.png"
        # print(f"Folder: {folder_name}, Expecting PNG: {expected_png_filename}")

        # Check and rename PNG file
        png_file_found = False
        actual_png_filename_for_json = "" # This will be the name to write into JSON

        try:
            items_in_folder = os.listdir(current_folder_path)
        except Exception as e:
            print(f"Error listing files in {current_folder_path}: {e}")
            continue

        for item in items_in_folder:
            if item.lower().endswith(".png"):
                png_file_found = True
                actual_png_filename_on_disk = item # Current name on disk
                
                if actual_png_filename_on_disk.lower() != expected_png_filename.lower():
                    old_png_path = os.path.join(current_folder_path, actual_png_filename_on_disk)
                    new_png_path = os.path.join(current_folder_path, expected_png_filename)
                    try:
                        # Safety: if a file with expected_png_filename already exists and it's not the same file
                        # (e.g. case difference on case-sensitive systems, or leftover from previous failed run)
                        if os.path.exists(new_png_path) and not os.path.samefile(old_png_path, new_png_path):
                             print(f"Warning: Target PNG {new_png_path} already exists. Deleting it before rename from {actual_png_filename_on_disk}.")
                             os.remove(new_png_path) # Remove the conflicting file
                        
                        os.rename(old_png_path, new_png_path)
                        print(f"In {folder_name}: Renamed PNG {actual_png_filename_on_disk} -> {expected_png_filename}")
                        actual_png_filename_for_json = expected_png_filename
                        corrected_count += 1
                    except Exception as e:
                        print(f"Error renaming PNG {old_png_path} to {new_png_path}: {e}")
                        actual_png_filename_for_json = actual_png_filename_on_disk # Use original if rename failed
                        # continue # Decide if we should skip JSON update if PNG rename fails
                else: # PNG name is already correct
                    actual_png_filename_for_json = expected_png_filename 
                break # Found the PNG, no need to check other files
        
        if not png_file_found:
            print(f"Warning: No PNG file found in {folder_name}")
            continue
        
        if not actual_png_filename_for_json: # Should be set if PNG was found
            print(f"Error: actual_png_filename_for_json not set for {folder_name} despite PNG being found. This is a bug.")
            continue

        # Check and update Contents.json
        contents_json_path = os.path.join(current_folder_path, "Contents.json")
        if os.path.exists(contents_json_path):
            try:
                # Read with utf-8-sig to handle potential BOM
                with open(contents_json_path, 'r', encoding='utf-8-sig') as f:
                    content = f.read()
                    # Attempt to strip trailing commas for more robust JSON parsing
                    content = re.sub(r',(\s*\n\s*)\}\'', r'\1}\'', content)
                    content = re.sub(r',(\s*\n\s*)\]\'', r'\1]\'', content)
                    data = json.loads(content)
                
                made_change_json = False
                if "images" in data and isinstance(data["images"], list) and len(data["images"]) > 0:
                    # Ensure the first image entry is a dictionary and has 'filename'
                    if isinstance(data["images"][0], dict) and \
                       data["images"][0].get("filename") != actual_png_filename_for_json:
                        data["images"][0]["filename"] = actual_png_filename_for_json
                        made_change_json = True
                else: # If structure is not as expected, log and potentially try to fix or skip
                    print(f"Warning: Unexpected structure or empty 'images' array in Contents.json for {folder_name}. Attempting to set filename if possible.")
                    if isinstance(data.get("images"), list): # if "images" is a list but maybe empty
                         if not data["images"]: # if empty list
                             data["images"].append({"filename": actual_png_filename_for_json, "idiom": "universal", "scale": "1x"})
                         else: # list is not empty but first element might be bad
                            if not isinstance(data["images"][0], dict):
                                data["images"][0] = {"filename": actual_png_filename_for_json, "idiom": "universal", "scale": "1x"}
                            else:
                                data["images"][0]["filename"] = actual_png_filename_for_json
                         made_change_json = True
                    else: # if "images" key doesn't exist or isn't a list
                        data["images"] = [{"filename": actual_png_filename_for_json, "idiom": "universal", "scale": "1x"}]
                        made_change_json = True
                
                if made_change_json:
                    with open(contents_json_path, 'w', encoding='utf-8') as f:
                        json.dump(data, f, indent=2) # Use indent=2 for consistency with original files
                    print(f"In {folder_name}: Updated Contents.json to reference {actual_png_filename_for_json}")
                    corrected_count += 1
                # else:
                #     print(f"In {folder_name}: Contents.json already correct for {actual_png_filename_for_json}.")

            except json.JSONDecodeError as je:
                print(f"Error: Could not parse Contents.json in {folder_name}. JSONDecodeError: {je}. File content was: {content[:200]}...") # Print first 200 chars
            except Exception as e:
                print(f"Error processing Contents.json in {folder_name}: {e}")
        else:
            print(f"Warning: Contents.json not found in {folder_name}. Creating it.")
            try:
                data = {
                    "images": [
                        {
                            "filename": actual_png_filename_for_json,
                            "idiom": "universal",
                            "scale": "1x"
                        },
                        {
                            "idiom": "universal",
                            "scale": "2x"
                        },
                        {
                            "idiom": "universal",
                            "scale": "3x"
                        }
                    ],
                    "info": {
                        "author": "xcode",
                        "version": 1
                    }
                }
                with open(contents_json_path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=2)
                print(f"In {folder_name}: Created Contents.json and set filename to {actual_png_filename_for_json}")
                corrected_count += 1
            except Exception as e:
                print(f"Error creating Contents.json in {folder_name}: {e}")
                
    print(f"\nFinished processing {processed_folders} items in the directory.")
    if corrected_count > 0:
        print(f"Made {corrected_count} corrections.")
    else:
        print("No corrections made (or all relevant items were already correct).")

if __name__ == "__main__":
    npc_assets_path = r"C:\\Repos\\CRProject\\CRProject\\Assets.xcassets\\NPCs" # Raw string for Windows path
    print(f"Script starting. Target path: {npc_assets_path}")
    
    if not os.path.isdir(npc_assets_path):
        print(f"Critical Error: The path {npc_assets_path} does not exist or is not a directory. Please check the path.")
    else:
        print("Path confirmed. Running asset fix.")
        try:
            fix_npc_assets(npc_assets_path)
        except Exception as e:
            print(f"An unexpected error occurred during script execution: {e}")
    print("Script finished.") 