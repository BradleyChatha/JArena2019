module jarena.core.services;

private
{
    import std.experimental.logger;
    import std.traits;
    import std.meta;
    import std.typecons : Flag;
    import std.typetuple : AliasSeq;
    import jarena.core;
}

version = ServiceProviderVerbose;

alias OverrideExisting = Flag!"override_";
alias IsSingleton      = Flag!"singleton";

final class ServiceProvider
{	
	struct ParamInfo
	{
		TypeInfo paramType;
		string paramName;
	}
	
	struct FactoryStackInfo
	{
		ServiceInfo service;
		bool wasInCache;
	}
	
	struct ServiceInfo
	{	
        IsSingleton isSingleton;
		TypeInfo baseType;
		TypeInfo implType;
		ParamInfo[] injectParams;
		Object singleton; // If applicable
        Object delegate() factoryFunc;
	}
	
    private
    {
        ServiceInfo[TypeInfo]  _services; // Key is the base type.
        FactoryStackInfo[]     _factoryStack;
        bool                   _factoryStackLock;
    }

    public
    {
        void addSingleton(Base, Implementation)(Base instance = null, OverrideExisting override_ = OverrideExisting.no)
        {
            this.add!(Base, Implementation)(instance, override_, IsSingleton.yes);
        }

        void addTransient(Base, Implementation)(OverrideExisting override_ = OverrideExisting.no)
        {
            this.add!(Base, Implementation)(null, override_, IsSingleton.no);
        }
        
        Base get(Base)(lazy Base default_ = null)
        {
            import std.algorithm : filter;
            import std.range     : retro;
            static assert(is(Base == interface), "The given type '"~Base.stringof~"' is not an interface.");

            // Gain the factory lock.
            bool weHaveLock = false;
            if(!this._factoryStackLock)
            {
                weHaveLock = true;
                this._factoryStackLock = true;
            }
            scope(exit)
            {
                if(weHaveLock)
                {
                    this._factoryStack.length = 0;
                    this._factoryStackLock = false;
                }
            }

            // Checks to make sure we don't have any circular references.
            void doCircularCheck()
            {
                int i = 0;
                foreach(info; this._factoryStack.retro.filter!(i => !i.wasInCache))
                {
                    if(i == 0) continue; // Skip the first once, since that's the one we just made
                    i++;

                    if(info.service.baseType == typeid(Base))
                    {
                        assert(false, "Circular reference detected. TODO: Better error message");
                    }
                }
            }

            this.verboseTracef("Getting '%s'.", Base.stringof);
            
            auto ptr = (typeid(Base) in this._services);
            if(ptr is null)
            {
                this.verboseTracef("Returning default value '%s'.", default_);
                return default_;
            }

            this._factoryStack ~= FactoryStackInfo(*ptr, false);

            if(ptr.isSingleton)
            {
                if(ptr.singleton is null)
                {
                    this.verboseTracef("Service is singleton without value. Creating value.");
                    doCircularCheck();
                    ptr.singleton = cast(Object)ptr.factoryFunc();
                }
                else
                    this._factoryStack[$-1].wasInCache = true;

                this.verboseTracef("Returning singleton service.");
                return cast(Base)ptr.singleton;
            }

            this.verboseTracef("Creating and returning transient service.");
            doCircularCheck();
            return cast(Base)ptr.factoryFunc();
        }
        
        T makeAndInject(T, Params...)(Params params)
        {
            import std.format : format;

            T obj;

            this.verboseTracef("Creating type '%s' with injections. Params = %s", T.stringof, (Params.length > 0) ? "%s".format(params) : "N/A");
            mixin(createInjectCall!(T, "obj", "__ctor", "", Params));
            
            return obj;
        }

        auto injectCall(string funcName, T, Params...)(ref scope T target, Params params)
        {
            import std.format : format;

            alias RetType = ReturnType!(__traits(getMember, T , funcName));

            this.verboseTracef("Calling function '%s.%s' with injections. Params = %s", T.stringof, funcName, (Params.length > 0) ? "%s".format(params) : "N/A");

            static if(is(RetType == void))
                mixin(createInjectCall!(T, "target", funcName, "", Params));
            else
            {
                mixin(createInjectCall!(T, "target", funcName, "result", Params));
                return result;
            }
        }

        auto injectCall(alias func, T, Params...)(ref scope T target, Params params)
        {
            return this.injectCall!(__traits(identifier, func))(target, params);
        }
    }
	
	private
    {
        void verboseTracef(Args...)(string str, Args args)
        {
            version(ServiceProviderVerbose)
                tracef(str, args);
        }

        void add(Base, Implementation)(Base instance, OverrideExisting override_, IsSingleton isSingleton)
        {
            static assert(is(Implementation : Base), "Type '"~Implementation.stringof~"' must inherit from '"~Base.stringof~"'");
            enforceAndLogf((typeid(Base) in this._services) is null || override_, 
                "Cannot override existing implementation for service '%s'",
                Base.stringof
            );

            tracef("Registering %s implementation '%s' of service '%s'", (isSingleton) ? "singleton" : "transient", Implementation.stringof, Base.stringof);

            ParamInfo[] params;
            alias InjectFunc  = InjectionCtorFor!Implementation;
            alias InjectNames = ParameterIdentifierTuple!InjectFunc;
            alias InjectTypes = Parameters!InjectFunc;
            static assert(InjectNames.length == InjectTypes.length);

            foreach(i, name; InjectNames)
                params ~= ParamInfo(typeid(InjectTypes[i]), name);

            this._services[typeid(Base)] = ServiceInfo(
                isSingleton,
                typeid(Base),
                typeid(Implementation),
                params,
                cast(Object)instance,
                () => cast(Implementation)this.makeAndInject!Implementation
            );
        }

        static dstring createInjectCall(T, string objectName, string targetFunc, string resultName, Params...)()
        {
            import std.format : format;
            import std.algorithm : joiner;
            import jaster.serialise.builder;

            auto code = new CodeBuilder();

            // Get the func to use, params, and some other constant stuff.
            static if(targetFunc == "__ctor")
                alias Func = InjectionCtorFor!T;
            else
                alias Func = __traits(getMember, T, targetFunc);
            alias FuncParams = Parameters!Func;
            alias ParamNames = ParameterIdentifierTuple!Func;
            enum NormalParamLength = NormalParamLength!Func;
            enum FirstServiceIndex = FirstServiceIndex!Func;

            // Make sure we've been given the right amount of parameters.
            static assert(Params.length == NormalParamLength,
                "Parameter count mis-match. Expected %s non-service parameters, but got %s. ".format(NormalParamLength, Params.length)
               ~"Missing Parameters: %s".format(ParamNames[Params.length..NormalParamLength])
            );

            // Put it in the generated code, since we need them there as well.
            code.putf(`static if("`~targetFunc~`" == "__ctor")
                           alias Func = InjectionCtorFor!T;
                       else
                           alias Func = __traits(getMember, T, "`~targetFunc~`");`);
            code.putf("alias FuncParams = Parameters!Func;");

            // Create an argument list.
            // For parameters passed to us, just pass to the function as is.
            // For services, call `this.get!ServiceType` on them.
            // For `ServiceProvider`, pass `this`.
            string[] paramsToUse;
            static foreach(i, param; FuncParams)
            {{
                static if(is(param == ServiceProvider))
                {
                    code.putf(`this.verboseTracef("Using 'this' for parameter %s (\"%s\")");`, i, ParamNames[i]);
                    paramsToUse ~= "this";
                }
                else static if(is(param == interface))
                {
                    code.putf(`this.verboseTracef("Using service '%s' for parameter %s (\"%s\")");`, param.stringof, i, ParamNames[i]);
                    paramsToUse ~= format("this.get!(FuncParams[%s])", i);
                }
                else
                {
                    static assert(i < NormalParamLength, 
                        "Service parameters (types of `interface` and `ServiceProvider`) must be placed *after* non-service parameters.\n"
                       ~"Non-service parameter #%s (%s %s) needs to be placed *before* Service parameter #%s (%s %s)."
                            .format(i, param.stringof, ParamNames[i],
                                    FirstServiceIndex, FuncParams[FirstServiceIndex].stringof, ParamNames[FirstServiceIndex])
                    );
                    code.putf(`this.verboseTracef("Using parameter %s (%s) for parameter %s (\"%s\")");`, i, Params[i].stringof, i, ParamNames[i]);
                    paramsToUse ~= format("params[%s]", i);
                }
            }}

            // For the constructor, create a new object (using objectName).
            // Otherwise, call the function, and optionally store it in a result.
            auto paramRange = paramsToUse.joiner(", ");
            static if(targetFunc == "__ctor")
                code.putf("%s = new T(%s);", objectName, paramRange);
            else static if(resultName.length > 0)
                code.putf("auto %s = %s.%s(%s);", resultName, objectName, targetFunc, paramRange);
            else
                code.putf("%s.%s(%s);", objectName, targetFunc, paramRange);

            return code.data.idup;
        }
    }
}

interface IConfig(T)
{
    @property
    ref T value();
}

class ConfigImpl(T) : IConfig!T
if(is(T == struct))
{
    private T _value;

    @property
    ref T value()
    {
        return this._value;
    }
}

void configure(T)(ServiceProvider service, void delegate(ref T) configurator)
{
    auto config = service.get!(IConfig!T);
    if(config is null)
    {
        service.addSingleton!(IConfig!T, ConfigImpl!T);
        config = service.get!(IConfig!T);
    }

    configurator(config.value);
}

private template NormalParamLength(alias Func)
{
    enum ParamFilter(T) = is(T == interface) || is(T == ServiceProvider);

    alias FuncParams   = Parameters!Func;
    alias FilterParams = Filter!(ParamFilter, FuncParams);
    
    enum NormalParamLength = (FuncParams.length - FilterParams.length);
}

private template FirstServiceIndex(alias Func)
{
    static size_t findIndex()
    {
        size_t index = size_t.max;

        foreach(i, param; Parameters!Func)
        {
            if(is(param == interface) || is(param == ServiceProvider))
            {
                index = i;
                break;
            }
        }

        return index;
    }

    enum FirstServiceIndex = findIndex();
}

private template InjectionCtorFor(alias Type)
{
    static if(__traits(hasMember, Type, "__ctor"))
    {
        alias Ctors = __traits(getOverloads, Type, "__ctor");
        static assert(Ctors.length > 0);

        static if(Ctors.length == 1)
            alias InjectionCtorFor = Ctors[0];
        else
        {
            enum CtorFilter(alias T) = Parameters!T.length > 0;
            alias Filtered = Filter!(CtorFilter, Ctors);
            static assert(Filtered.length > 0);

            alias InjectionCtorFor = Filtered[0];
        }
    }
    else
        alias InjectionCtorFor = defaultCtor;
}

private void defaultCtor() {}

version(unittest)
{
    string LAST_LOGGED_MESSAGE;

    interface ILoggerService
	{
		void write(int level, string str);
	}

	// Just pretend they're using writeln instead of putting them into a variable.
	// They return the strings so I can easily test them.
	// An alternative way would be to create an `IOutputService` and use that to get the output.
	// But for this test, all I want to do is test injection, and I only need one class for that.
	class MinimalConsoleLoggerService : ILoggerService
	{
		void write(int level, string str)
		{
			LAST_LOGGED_MESSAGE = str;
		}
	}

	class DetailedConsoleLoggerService : ILoggerService
	{
		void write(int level, string str)
		{
			LAST_LOGGED_MESSAGE = ((level == 0) ? "[INFO] " : "[ERROR] ") ~ str;
		}
	}

	class SomeImportantClass
	{
		ILoggerService logger;
		
		this(ILoggerService logger)
		{
			this.logger = logger;
			logger.write(0, "Ctor injection");
		}
	}

    class SomeUnrelatedClass
    {
        void doLog(string myNonServiceParam, ILoggerService service)
        {
            service.write(1, myNonServiceParam);
        }
    }

    struct SomeConfig
    {
        string name;
    }

    class SomeClassWithConfig
    {
        this(IConfig!SomeConfig config, ILoggerService logger)
        {
            logger.write(0, config.value.name);
        }
    }
}

// TEST CASE
unittest
{	
	auto services = new ServiceProvider();

    alias Parameters = AliasSeq;
	
	// Test using a previously-registered service.
	services.addTransient!(ILoggerService, MinimalConsoleLoggerService);
	
	services.makeAndInject!(SomeImportantClass)();
	assert(LAST_LOGGED_MESSAGE == "Ctor injection");
	
	// Test using an overrided service.
    services.addTransient!(ILoggerService, DetailedConsoleLoggerService)(OverrideExisting.yes);
	services.makeAndInject!(SomeImportantClass)();
	assert(LAST_LOGGED_MESSAGE == "[INFO] Ctor injection", LAST_LOGGED_MESSAGE);

    // Test call injections
    auto foo = new SomeUnrelatedClass();
    services.injectCall!(SomeUnrelatedClass.doLog)(foo, "Foz");
    services.injectCall!"doLog"(foo, "Foz"); // Alternate way
    assert(LAST_LOGGED_MESSAGE == "[ERROR] Foz", LAST_LOGGED_MESSAGE);

    // Test configuration.
    services.configure!SomeConfig((ref c) { c.name = "EXPLOSION"; });
    services.makeAndInject!SomeClassWithConfig();
    assert(LAST_LOGGED_MESSAGE == "[INFO] EXPLOSION", LAST_LOGGED_MESSAGE);
}