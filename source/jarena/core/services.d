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

//version = ServiceProviderVerbose;

/// Passed to the various `ServiceProvider.addXXX` functions.
alias OverrideExisting = Flag!"override_";

/++
 + A UDA that can be attached to function parameters.
 +
 + Normally, a Service Parameter (a parameter the Service Provider will detect as a service, and
 + will attempt to perform an injection on) is defined as either being a parameter taking an `interface`,
 + or a parameter taking a `ServiceProvider`.
 +
 + Attaching this UDA onto a parameter will force the service provider to treat the parameter as a service,
 + and will force it to perform an injection on that parameter (like it does for any other service).
 +
 + Use_Case:
 +  Take JEngine's `Renderer` class for example. There's only ever going to be *one* renderer for this engine,
 +  so it's bit of a waste of time to make an interface for it just so it can be used with the service provider
 +  (not to mention the issues with templated functions when being used with interfaces).
 +
 +  So instead of doing something such as `provider.addSingleton!(IRenderer, OpenGLRenderer)(rendererInstance)`, you do
 +  `provider.addSingleton!(Renderer, Renderer)(rendererInstance)`. So there is simply one class, `Renderer`, which is both
 +  the service base class, but also the service implementation class.
 +
 +  Now, this isn't an `interface`, so the service provider won't perform an injection on it anytime we use it as a parameter.
 +  So we attach `@FromService` onto it to force the provider to perform the injection.
 +
 +  `void onRender(@FromService Renderer renderer)`
 +
 +  Side note - Depending on how many services a function takes, the injection process can be relatively expensive.
 +  So try to avoid using on hot functions. You can do this by getting the services at another point in time (e.g the constructor),
 +  or caching the results of `ServiceProvider.get` and passing them manually.
 +
 +  Side side note - I beg to holy saint Walter Bright to make working with function parameter UDAs easier ;_;
 + ++/
struct FromServices{}

/++
 + A container for services.
 +
 + A service is a class that, as the name implies, provides a certain service.
 +
 + This class is heavily inspired from ASP Core's ServiceProvider. So alongside being a Service Locator,
 + it also acts as a dependency injector.
 +
 + How to use:
 +  Services can be registered via `addSingleton` and `addTransient`.
 +
 +  Services can then be retrieved using `get`.
 +
 +  The service provider can inject parameters into function calls (including the constructor) via
 +  `injectCall` and `makeAndInject`.
 +
 + Versions:
 +  If the `ServiceProviderVerbose` `version` is specified, then this class will provide verbose logging of it's actions.
 + ++/
final class ServiceProvider
{	
    private
    {
        alias IsSingleton = Flag!"singleton";
	
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

        ServiceInfo[TypeInfo]  _services; // Key is the base type.
        FactoryStackInfo[]     _factoryStack;
        bool                   _factoryStackLock;
    }

    public
    {
        /++
         + Registers a service.
         +
         + Lifetimes:
         +  Similar to the ASP counter parts, there are two lifetimes for a service.
         +
         +  Singleton - Where a single instance is created for the service, and is then used for every request for the service.
         +
         +  Transient - Where a new instance is created every time the service is reqeuested for.
         +
         + Decoupling:
         +  You may have noticed the two template parameters, `Base`, and `Implementation`.
         +
         +  This class aims to allow the user code to decouple from the implementation of a class, and it's interface.
         +
         +  For example, you may have an `ILoggerService` interface (which would be used as the `Base`) and several
         +  implementations such as a `FileLogger`, `ConsoleLogger`, `CompoundLogger`, etc. (Which would be used as the `Implementation`).
         +
         +  The user code doesn't exactly care what implementation it gets in most cases, all they care is that they get an `ILoggerService`.
         +
         +  So this function is used to associate a certain implementation of a service, to it's interface, and then the user code can
         +  blindly ask for the service's interface without having to know it's nitty-gritty details.
         +
         +  However, there are certainly some cases where there will only ever be one concrete implementation of an interface.
         +  In cases like these, you can simply specify both the `Base` and `Implementation` to be of the implementing class.
         +
         +  There is a slight quirk with this however, as it will require you to use the `@FromServices` UDA for function parameters (please refer to it's
         +  documentation).
         +
         + Injection:
         +  Please refer to `injectCall` and `makeAndInject`.
         +
         + Params:
         +  [Base]           = The interface/base class of the service. This should be defined well enough that the user shouldn't have to cast it
         +  [Implementation] = The implementation class of the service.
         +  instance         = [Singletons only] The instance to use for the singleton.
         +                     If this is null, then an instance will be created by `get`, using `makeAndInject` under the hood.
         +  override_        = Determines whether to override any existing implementation for the `Base` service.
         +                     If `OverrideExisting.no` and an implementation already exists, then an exception is thrown. 
         + ++/
        void addSingleton(Base, Implementation)(Base instance = null, OverrideExisting override_ = OverrideExisting.no)
        {
            this.add!(Base, Implementation)(instance, override_, IsSingleton.yes);
        }

        /// ditto
        void addTransient(Base, Implementation)(OverrideExisting override_ = OverrideExisting.no)
        {
            this.add!(Base, Implementation)(null, override_, IsSingleton.no);
        }
        
        /++
         + Creates and/or returns an instance of the specified service.
         +
         + Service Creation:
         +  All services are created using the `makeAndInject` function on their implementation class.
         +  This allows services to be injected with other services fluently.
         +
         +  For singletons, if an instance of the service doesn't exist yet, then an instance is created, cached, then returned.
         +  If an instance has already been cached, then it's returned.
         +
         +  For transient, an instance is created everytime this function is called.
         +
         + Params:
         +  [Base]   = The interface/base class of the service. This will be the same `Base` parameter passed to `addSingleton` and `addTransient`.
         +  default_ = What to return if the service doesn't exist.
         +
         + Returns:
         +  The instance of the service, or `default_` if the service doesn't exist.
         + ++/
        Base get(Base)(lazy Base default_ = null)
        {
            import std.algorithm : filter;
            import std.range     : retro;
            static assert(is(Base == interface) || is(Base == class), "The given type '"~Base.stringof~"' is neither an interface nor a class.");

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
        
        /++
         + Calls the constructor for a type, performing the same injection process documented
         + by `injectCall`.
         +
         + Notes:
         +  If it wasn't obvious, if `T` is a class then the GC is used to allocate it's memory.
         +
         +  This function will select a ctor that contains parameters, instead of a constructor that takes no parameters, if both
         +  types of constructors exist in the same type.
         +
         + Params:
         +  [T]     = The type to construct.
         +  params  = The non-service (see `injectCall`) parameters to pass.
         +
         + Returns:
         +  The newly constructed `T`.
         + ++/
        T makeAndInject(T, Params...)(Params params)
        {
            import std.format : format;

            T obj;

            this.verboseTracef("Creating type '%s' with injections. Params = %s", T.stringof, (Params.length > 0) ? "%s".format(params) : "N/A");
            mixin(createInjectCall!(T, "obj", "__ctor", "", Params));
            
            return obj;
        }

        /++
         + Calls a function, performing service injection in the process.
         +
         + Overloaded functions:
         +  It is unwise to use injection with functions that have overloads, as there's no easy way to specify/determine
         +  which overload needs to be used. It'll just use whichever one the compiler returns from `__traits(getMember)`.
         +
         + Injection:
         +  Injection is the process of automatically passing over dependencies/services that the function needs.
         +
         +  The service provider detects a Service parameter as being: a parameter who's type is an interface; a parameter
         +  who's type is `ServiceProvider`; a parameter who has been marked with the `@FromServices` UDA.
         +
         +  For a service parameter who's type is `ServiceProvider`, the current instance of this class is passed to the parameter.
         + 
         +  For any other service parameter, the return value of `this.get!TypeOfParameter` is passed to it.
         +
         +  For non-service parameters (parameters that don't meet the criteria above), the given `params` are passed.
         +
         +  Functions that are being injected have a strict order for how their parameters are laid out -
         +  Non-service parameters must always come before a service parameter. The service provider will enforce this with a compile time check,
         +  and will provide a detailed error message on what's wrong with the parameters if it does not meet the right criteria.
         +
         +  If the number of `params` passed differs from from the number of non-service parameters for the function, a compile time assert
         +  will fail, listing all of the parameters that still need to be passed (if not enough parameters were passed).
         +
         +  An assert will also fail if a circular dependency is detected. Due to the nature of how this class works, this can only be detected
         +  at runtime currently.
         +
         +  Do note that currently default parameters are not supported (but there's no technical reason they can't be).
         +
         + UFCS:
         +  Currently, there is no support for UFCS. The issue is that this class needs to have the module of the UFCS function
         +  imported, and there isn't really an easy way to do that.
         +
         +  A possibility in the future is to provide a mixin that can be used inside a module to provide the functionality needed
         +  for UFCS injection.
         +
         + Params:
         +  [funcName] = The name of the function to inject and call.
         +  target     = The instance of `T` to call the function with.
         +  params     = The non-service params to pass to the function. (See the 'Injection' section if you haven't already).
         +
         + Returns:
         +  Whatever `funcName` returns.
         + ++/
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

        /++
         + A helper function for the other `injectCall` overload, that takes the name of the given `func` instead
         + of taking a direct string.
         +
         + E.g. instead of `injectCall!"MyFunc"` you do `injectCall!(MyObject.MyFunc)`
         + ++/
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
            static foreach(i; 0..FuncParams.length)
            {{
                alias param = FuncParams[i];
                static if(is(param == ServiceProvider))
                {
                    code.putf(`this.verboseTracef("Using 'this' for parameter %s (\"%s\")");`, i, ParamNames[i]);
                    paramsToUse ~= "this";
                }
                else static if(is(param == interface) 
                            || (
                                    is(typeof(canFindFromServices!(__traits(getAttributes, FuncParams[i..i+1]))))
                                 && canFindFromServices!(__traits(getAttributes, FuncParams[i..i+1]))
                               )
                            )
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
                code.putf("%s = %s T(%s);", is(T == class) ? "new" : "", objectName, paramRange);
            else static if(resultName.length > 0)
                code.putf("auto %s = %s.%s(%s);", resultName, objectName, targetFunc, paramRange);
            else
                code.putf("%s.%s(%s);", objectName, targetFunc, paramRange);

            return code.data.idup;
        }
    }
}

/++
 + The base class for a configuration.
 +
 + Please see the `configure` function.
 + ++/
interface IConfig(T)
{
    @property
    ref T value();
}

/// The implementation for a configuration.
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

// TODO: Rewrite this a bit, since I question if it's even valid English (in terms of it making no fucking sense).
/++
 + Using a struct (`T`) to store some form of configuration, this function will register
 + a singleton service (`IConfig!T`) into the given `ServiceProvider`.
 +
 + Notes:
 +  `configurator` will be passed an already existing version of the configuration if it exists.
 +  Otherwise a new instance of it will be used.
 +
 + Use Case:
 +  Sometimes a service will allow the user to configure how it works.
 +  
 +  It can support this by defining a struct to store the configuration, and then using
 +  the `IConfig` interface alongside the configuration struct and dependency injection
 +  to retrieve this configuration.
 +
 + Params:
 +  service      = The service provider to use.
 +  configurator = The function that will configure the data.
 + ++/
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
    size_t doCount()
    {
        size_t serviceParamCount = 0;

        forEveryServiceParam!Func((i){ serviceParamCount++; });

        return (Parameters!Func.length - serviceParamCount);
    }
    
    enum NormalParamLength = doCount;
}

private bool canFindFromServices(Attribs...)()
{
    bool value;
    static foreach(attrib; Attribs)
    {
        static if(is(attrib == FromServices))
            value = true;
    }

    return value;
}

private template FirstServiceIndex(alias Func)
{
    static size_t findIndex()
    {
        size_t index = size_t.max;

        forEveryServiceParam!Func((i){ if(index == size_t.max) index = i; });

        return index;
    }

    enum FirstServiceIndex = findIndex();
}

private void forEveryServiceParam(alias Func)(void delegate(size_t) func)
{
    alias Params = Parameters!Func;
    static foreach(i; 0..Params.length)
    {{
        alias param = Params[i];
        if(is(param == interface) || is(param == ServiceProvider))
            func(i);

        static if(is(typeof(__traits(getAttributes, Params[i..i+1]))))
        {
            if(canFindFromServices!(__traits(getAttributes, Params[i..i+1])))
                func(i);
        }
    }}
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
        SomeConfig value;
        this(IConfig!SomeConfig config, ILoggerService logger)
        {
            logger.write(0, config.value.name);
            this.value = config.value;
        }
    }

    class SomeClassWithUDA
    {
        this(@FromServices SomeClassWithConfig config, ILoggerService logger)
        {
            logger.write(0, config.value.name ~ "YEET");
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
    auto configObj = services.makeAndInject!SomeClassWithConfig();
    assert(LAST_LOGGED_MESSAGE == "[INFO] EXPLOSION", LAST_LOGGED_MESSAGE);

    // Non-interface based injection
    services.addSingleton!(SomeClassWithConfig, SomeClassWithConfig)(configObj);
    services.makeAndInject!SomeClassWithUDA();
    assert(LAST_LOGGED_MESSAGE == "[INFO] EXPLOSIONYEET");
}