import json
from collections import Counter

# Read the file
with open('Data/NPCs.json', 'r') as f:
    npcs = json.load(f)

# Count frequencies of homeLocationId
home_counts = Counter(npc['homeLocationId'] for npc in npcs)

# Track which IDs we've processed and how many we've kept
processed = Counter()

# Create new list with reduced duplicates
new_npcs = []
for npc in npcs:
    home_id = npc['homeLocationId']
    if home_counts[home_id] > 2:  # If there are more than 2 NPCs with this home
        if processed[home_id] < (home_counts[home_id] // 2):  # Keep half
            new_npcs.append(npc)
            processed[home_id] += 1
    else:
        new_npcs.append(npc)  # Keep all NPCs from locations with 2 or fewer

# Save the modified file
with open('Data/NPCs.json', 'w') as f:
    json.dump(new_npcs, f, indent=2)

# Print statistics
print(f'Original NPC count: {len(npcs)}')
print(f'New NPC count: {len(new_npcs)}')
print('\nSome sample home location counts (before -> after):')
for home_id in sorted(list(home_counts.keys())[:10]):
    original = home_counts[home_id]
    new_count = sum(1 for npc in new_npcs if npc['homeLocationId'] == home_id)
    if original != new_count:
        print(f'Location {home_id}: {original} -> {new_count}') 