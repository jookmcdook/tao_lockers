Config = {}

Config.StorageTiers = {
        small = {
            label = 'Small Storage',
            price = 12000, -- $12k per week
            weight = 6000, -- 6000 weight
            weaponLimit = 3, -- 3 weapons maximum
            slots = 30
        },
        medium = {
            label = 'Medium Storage',
            price = 38000, -- $38k per week
            weight = 9000, -- 9000 weight
            weaponLimit = 8, -- 8 weapons maximum
            slots = 50
        },
        large = {
            label = 'Large Storage',
            price = 215000, -- $215k per week
            weight = 25000, -- 25k weight
            weaponLimit = 45, -- 45 weapons maximum
            slots = 80
        }
    }

Config.AccessLocations = {
        -- Example locations - add more as needed
         { coords = vec3(575.49, 136.91, 99.47), label = 'Storage' },
         { coords = vec3(1224.18, -481.71, 66.41), label = 'Storage' },
         { coords = vec3(1164.26, -1311.24, 34.86), label = 'Storage' },
         { coords = vec3(1481.09, -1915.5, 71.46), label = 'Storage' },
         { coords = vec3(1037.55, -2177.33, 31.53), label = 'Storage' },
         { coords = vec3(814.75, -1636.0, 30.99), label = 'Storage' },
         { coords = vec3(817.27, -924.57, 26.23), label = 'Storage' },
    }

    -- Grace period in hours before locker deletion when rent is not paid
Config.GracePeriod = 24 

    -- UI Settings
Config.CircleRadius = 0.6
Config.SphereColor = { 
        94, 176, 242, 80, -- r, g, b, a
    }
Config.LineColor = {
        94, 176, 242, 80, -- r, g, b, a
    }