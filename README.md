# Tao Lockers - Storage Rental System

A comprehensive storage rental system for FiveM servers using QBX-Core and OX Framework.

## Features

- **Three Storage Tiers**: Small, Medium, and Large with different capacities
- **Weekly Rent System**: Automatic rent collection with grace period
- **Upgrade/Downgrade**: Change storage tiers as needed
- **Weapon Limits**: Configurable weapon limits per storage tier
- **Multiple Locations**: Access storage from various locations around the map
- **OX Inventory Integration**: Seamless integration with ox_inventory
- **QBX-Core Support**: Full compatibility with QBX-Core framework

## Dependencies

- `qbx-core`
- `ox_lib`
- `ox_inventory`
- `oxmysql`
- `ox_target`

## Installation

1. Download and place the resource in your server's resources folder
2. Add `ensure tao_lockers` to your server.cfg
3. Configure the storage locations in `config.lua`
4. Restart your server

## Configuration

### Storage Tiers

The script includes three storage tiers with different capacities:

- **Small Storage**: $12,000/week, 6,000 weight, 3 weapons max, 30 slots
- **Medium Storage**: $38,000/week, 9,000 weight, 8 weapons max, 50 slots  
- **Large Storage**: $215,000/week, 25,000 weight, 45 weapons max, 80 slots

### Access Locations

Configure storage access points in `config.lua`:

```lua
Config.AccessLocations = {
    { coords = vec3(575.49, 136.91, 99.47), label = 'Storage' },
    { coords = vec3(1224.18, -481.71, 66.41), label = 'Storage' },
    -- Add more locations as needed
}
```

### Settings

- `Config.GracePeriod`: Hours before storage deletion when rent is unpaid (default: 24)
- `Config.CircleRadius`: Radius of interaction zones (default: 0.6)
- `Config.SphereColor`: Color of interaction zones (RGBA)

## Usage

1. **Renting Storage**: Approach any storage location and interact to rent storage
2. **Accessing Storage**: Use the same interaction to access your storage inventory
3. **Upgrading**: Change to a larger storage tier (additional cost applies)
4. **Downgrading**: Change to a smaller storage tier (warning: excess items will be lost)
5. **Cancelling**: Cancel your rental (warning: all items will be lost)

## Database

The script automatically creates a `player_storage` table with the following structure:

- `id`: Auto-increment primary key
- `citizenid`: Player's citizen ID
- `tier`: Storage tier (small/medium/large)
- `stash_id`: Unique stash identifier
- `last_rent_paid`: Timestamp of last rent payment
- `created`: Timestamp when storage was created

## Events

### Client Events

- `tao_lockers:client:setPlayerStorage`: Sets player's storage data
- `tao_lockers:client:storageRented`: Called when storage is rented
- `tao_lockers:client:storageUpgraded`: Called when storage is upgraded
- `tao_lockers:client:storageDowngraded`: Called when storage is downgraded
- `tao_lockers:client:storageCancelled`: Called when storage is cancelled
- `tao_lockers:client:rentDue`: Called when rent is due
- `tao_lockers:client:gracePeriod`: Called when grace period begins

### Server Events

- `tao_lockers:server:rentStorage`: Rent storage (tier parameter)
- `tao_lockers:server:upgradeStorage`: Upgrade storage (new tier parameter)
- `tao_lockers:server:downgradeStorage`: Downgrade storage (new tier parameter)
- `tao_lockers:server:cancelStorage`: Cancel storage rental

## License

This resource is licensed under the MIT License.
