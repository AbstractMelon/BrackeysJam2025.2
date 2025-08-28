# Location System Documentation

### Creating New Locations

1. Create a new `.tscn` file in `scenes/locations/`
2. Add BaseLocation script to root node
3. Include these required nodes:
   - `PlayerSpawn` (Marker3D) - Where player spawns
   - `ReturnPad` (Area3D) - Yellow glowing pad to return to kitchen
   - `ItemSpawner` - For spawning items
4. Add collision shapes for ReturnPad
5. Connect ReturnPad's `body_entered` signal (handled by BaseLocation)
