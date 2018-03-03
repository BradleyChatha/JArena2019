///
module jarena.core.cache;

private
{
    import std.traits : isType;
    import std.meta   : allSatisfy;
}

///
class Cache(T)
if(isType!T)
{
    import std.experimental.logger, std.traits : fullyQualifiedName;

    static if(is(T == class))
        enum defaultValue = null;
    else
        enum defaultValue = T.init;
    
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
        T get(string key, T default_ = defaultValue)
        {
            tracef("Fetching the %s with the key of '%s' from the cache", TName, key);
            
            auto ptr = (key in this._cache);
            if(ptr is null)
            {
                tracef("Unable to find the %s, returning default value", TName);
                return default_;
            }
            else
            {
                tracef("Found the %s, returning the cached value", TName);
                return *ptr;
            }
        }

        ///
        @safe @nogc
        bool hasKey(string key) nothrow const
        {
            return (key in this._cache) !is null;
        }
    }
}

private void _isMultiCache(Types...)(MultiCache!Types) {}

///
enum isMultiCache(T) = is(typeof(_isMultiCache(T.init)));

/++
 + A cache that holds multiple different caches for different types.
 +
 + Notes:
 +  For each type given, a new `Cache` is instantiated and stored in this cache.
 +
 +  For each type given, two functions are generated.
 +
 +  The first is a 'get' function which is identicle to the `Cache.get` function.
 +  However, you must specify which type you want to get using a template parameter.
 +  For example, `multiCache.get!int("Blah", int.max)` to use the cache for `int`s.
 +
 +  The second is a 'getCache' function which returns the `Cache` for a certain type.
 +  e.g `multCache.getCache!int` returns the `Cache!int` that's being used internally.
 +
 + Params:
 +  Types = The types to store in this cache.
 + ++/
class MultiCache(Types...)
if(allSatisfy!(isType, Types))
{
    static assert(isMultiCache!(typeof(this)));

    ///
    alias TypesStored = Types;

    private
    {
        mixin(genCacheVariables());
    }

    public
    {
        mixin(genConstructor());
        mixin(genGetFunctions());
        mixin(genGetCacheFunctions());
    }

    // Code gen functions
    private static
    {
        string makeCacheName(T)()
        if(isType!T)
        {
            import std.traits : fullyQualifiedName;
            import std.array  : split;
            import std.format : format;

            return format("_%sCache", fullyQualifiedName!T.split(".")[$ - 1]);
        }

        dstring genConstructor()
        {
            import codebuilder;
            auto builder = new CodeBuilder();

            builder.putf("this()");
            builder.putScope((_)
            {
                foreach(type; Types)
                {
                    import std.traits : fullyQualifiedName;
                    builder.putf("%s = new Cache!(%s)();", makeCacheName!type, fullyQualifiedName!type);
                }
            });

            return builder.data.idup;
        }

        dstring genCacheVariables()
        {
            import codebuilder;
            auto builder = new CodeBuilder();

            foreach(type; Types)
            {
                import std.traits : fullyQualifiedName;
                builder.putf("Cache!(%s) %s;", fullyQualifiedName!type, makeCacheName!type);
            }

            return builder.data.idup;
        }

        dstring genGetFunctions()
        {
            import codebuilder;
            auto builder = new CodeBuilder();

            foreach(type; Types)
            {
                import std.traits : fullyQualifiedName;
                auto cacheName = makeCacheName!type;
                auto typeName  = fullyQualifiedName!type;

                builder.putf("%s get(T = %s)(string key, T default_ = (Cache!(%s)).defaultValue)", typeName, typeName, typeName);
                builder.putf("if(is(T == %s))", typeName);
                builder.putScope((_)
                {
                    builder.putf("return %s.get(key, default_);", cacheName);
                });
            }

            return builder.data.idup;
        }

        dstring genGetCacheFunctions()
        {
            import codebuilder;
            auto builder = new CodeBuilder();

            foreach(type; Types)
            {
                import std.traits : fullyQualifiedName;
                auto cacheName = makeCacheName!type;
                auto typeName  = fullyQualifiedName!type;

                builder.putf("Cache!(%s) getCache(T = %s)()", typeName, typeName);
                builder.putf("if(is(T == %s))", typeName);
                builder.putScope((_)
                {
                    builder.putf("return %s;", cacheName);
                });
            }

            return builder.data.idup;
        }
    }
}

version(release)
{
}
else
    alias __TestCache = MultiCache!(int, string, float);