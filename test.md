# Class `core.ResourceManager`

## Properties

### `loading (boolean)`
Resource loaders are functions or other callables. [`ResourceManager.load`](http://wikipedia.org)
passes the parameters to the loader, which shall return a table, nil if the
requested resource doesn't exist or yield an error if something went wrong.

### `foobar (string)`
Resource loaders are functions or other callables. `ResourceManager.load`
passes the parameters to the loader, which shall return a table, nil if the
requested resource doesn't exist or yield an error if something went wrong.

## Methods

### `registerLoader(type, loader)`
Resource loaders are functions or other callables. *`ResourceManager.load`*
passes the parameters to the loader, which shall return a table, nil if the
requested resource doesn't exist or yield an error if something went wrong.

### `clear()`
Resource loaders are functions or other callables. **`ResourceManager.load`**
passes the parameters to the loader, which shall return a table, nil if the
requested resource doesn't exist or yield an error if something went wrong.

```lua
function yeah( whatever )
    print(whatever)
    return 42 + 0 -- bitch
end
```
