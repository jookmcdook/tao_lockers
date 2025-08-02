function hasPlyLoaded()
    return LocalPlayer.state.isLoggedIn
end

function DoNotification(text, nType)
    lib.notify({
        title = 'Storage System',
        description = text,
        type = nType
    })
end

exports('hasPlyLoaded', hasPlyLoaded)
exports('DoNotification', DoNotification)