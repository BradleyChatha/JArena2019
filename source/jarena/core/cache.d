module jarena.core.cache;

///
class Cache(T)
{
    import std.experimental.logger, std.traits : fullyQualifiedName;
    
    private
    {
        const TName = fullyQualifiedName!T;

        T[string] _cache;
    }

    public
    {
        ///
        T add(string key, T object)
        {
            import std.exception : enforce;
            import std.format    : format;

            tracef("Cacheing the %s with the key of '%s'", TName, key);
            enforce((key in this._cache) is null, 
                    format("There is already a(n) %s being cached with the key '%s'", TName, key));

            this._cache[key] = object;
            return object;
        }

        ///
        T get(string key, T default_ = null)
        {
            tracef("Fetching the %s with the key of '%s' from the cache", TName, key);
            
            auto ptr = (key in this._cache);
            if(ptr is null)
            {
                tracef("Unable to find the %s, returning default value", TName);
                return null;
            }
            else
            {
                tracef("Found the %s, returning the cached value", TName);
                return *ptr;
            }
        }
    }
}