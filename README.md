### Key item for ox_inventory

```lua
['carkeys'] = {
    label = 'Car Keys',
    weight = 50,
    stack = false,
    close = true,
    description = 'Keys for your vehicle'
},
```
### Event to give key.
```lua
TriggerServerEvent('op-carlock:givekey', plate)
```
### Event to remove key.
```lua
TriggerServerEvent('op-carlock:removekey', plate)
```
