/++
 + Contains code for a (witty named) event dispatcher.
 + ++/
module jarena.core.post;
private
{
    import std.experimental.logger, std.experimental.allocator.mallocator, std.experimental.allocator;
}

/++
 + The base class for any mail that can be posted to a `PostOffice`.
 + ++/
abstract class Mail
{
    /// The type used as the Mail's type.
    alias MailTypeT = ushort;
    private
    {
        MailTypeT _type;
    }

    public
    {
        /++
         + Base constructor for `Mail`.
         + 
         + Params:
         +  type = The type of data this mail represents.
         +         e.g. MyMailTypes.CLOSE_WINDOW
         + ++/
        @safe @nogc
        this(MailTypeT type) nothrow
        {
            this._type = type;
        }

        /++
         + Notes:
         +  The mail's type is just a number associated with it, it's generally used as a "command".
         +  For example, a mail of type "SomeEnum.DESTROY_WINDOW" would tell something to destroy it's window.
         + 
         + Returns:
         +  The type of the `Mail`.
         + ++/
        @property @safe @nogc
        MailTypeT type() nothrow pure const
        {
            return this._type;
        }

        /++
         + Sets the new type for this mail.
         +
         + Notes:
         +  Changing a mail's type while it is being processed by the PostOffice is undefined behaviour.
         +
         +  This functionality mostly exists for cases where constantly having to remake a Mail object is undesirable.
         + ++/
        @property @safe @nogc
        void type(MailTypeT newType) nothrow
        {
            this._type = newType;
        }
    }
}
///
unittest
{
    class C : Mail
    {
        this()
        {
            super(20);
        }
    }
    auto c = new C();
    assert(c.type == 20);
}

/++
 + The interface for any class that can subscribe for any kind of `Mail` at a `PostOffice`.
 + ++/
interface IPostBox
{
    /++
     + Called when any mail is mailed to a `PostOffice` the class is subscribed to.
     + 
     + Usage:
     +  $(P Inheriting class `PostOffice.subscribe`s to a post office.)
     +  $(P Some other part of the code posts a mail of any type.)
     +  $(P Inheriting class is given the mail, and decides whether it's worth of it's time or not.)
     + 
     + Assertions:
     +  Neither parameter can be `null`.
     + 
     + Notes:
     +  A helper mixin function `IPostBox.generateOnMail` can be used to map functions annotated with `@MailBox`
     +  automagically to a message (Praise be for D's super easy yet powerful meta-programming).
     + 
     + Params:
     +  office = The office that recieved the mail.
     +  mail   = The `Mail` that was posted.
     + ++/
    void onMail(PostOffice office, Mail mail)
    in
    {
        assert(office !is null, "The PostOffice is null.");
        assert(mail   !is null, "The mail is null. (senpai didn't love you enough)");
    }

    /++
     + Generates the `onMail` function, that will look over a type, and generate a switch-case statement that maps
     + a certain type of mail (defined using `@MailBox(SomeNumber)` on a function) to a function.
     + 
     + Notes:
     +  Any `@MailBox` function should only contain two parameters, which is a `PostOffice`, and a
     +  class that inherits from `Mail` in some way.
     + 
     +  The mail recieved will be casted to this type, and an assert is thrown if the mail recieved could not be casted to
     +  the type of the function's second parameter(which should be the class inehriting `Mail`).
     + 
     + Params:
     +  T = The class to make the `onMail` function for.
     + ++/
    public static final string generateOnMail(T : IPostBox)()
    {
        import std.meta;
        import std.traits;
        import std.format;
        import std.array     : array;
        import std.algorithm : splitter;

        string output  = "void onMail(PostOffice office, Mail mail)\n{";
               output ~= "\tswitch(mail.type)\n\t{";

        alias funcs = getSymbolsByUDA!(T, MailBox);
        static assert(allSatisfy!(isSomeFunction, funcs), "@MailBox can only be used on functions.");

        foreach(func; funcs)
        {
            enum udas = getUDAs!(func, MailBox);
            static assert(udas.length == 1, "Only 1 @MailBox may be used. Offender = " ~ func.stringof);

            enum  funcName    = fullyQualifiedName!func;
            enum  uda         = udas[0];
            alias paramTypes  = Parameters!func;
            static assert(paramTypes.length == 2,           "An @MailBox function should only have 2 parameters.");
            static assert(is(paramTypes[0]  == PostOffice), "The first parameter to an @MailBox function should be a PostOffice.");
            static assert(is(paramTypes[1]   : Mail),       "The second parameter to an @MailBox function should be a class that inherits from Mail.");

            output ~= format("\t\tcase %s:\n",                                                                    uda.type);
            output ~= format("\t\t\tauto casted = cast(%s)mail;\n",                                               paramTypes[1].stringof);
            output ~= format("\t\t\tassert(casted !is null, \"For mailbox %s, unable to cast mail to %s.\");\n",  funcName, paramTypes[1].stringof);
            output ~= format("\t\t\t%s(office, casted);\n",                                                       funcName.splitter(".").array[$-1]);
            output ~= format("\t\t\tbreak;\n");
        }

        output ~= "\t\tdefault: break;\n";
        output ~= "\n\t}\n}";
        return output;
    }
    ///
    unittest
    {
        static class C : IPostBox
        {
            mixin(IPostBox.generateOnMail!C);

            bool eventCalled = false;

            // The mailed message will automatically be casted to `ValueMail!bool` before being passed.
            @MailBox(1)
            void onSomeEvent(PostOffice office, ValueMail!bool mail)
            {
                assert(mail.type == 1);
                assert(mail.value);

                eventCalled = true;
            }

            @MailBox(400)
            void onOtherEvent(PostOffice office, CommandMail mail)
            {
                assert(mail.type == 400);
            }
        }

        auto office = new PostOffice(); // This isn't used in the example, but "onMail" requires it to have a non-null office.
        auto myC    = new C();
        assert(!myC.eventCalled);
        myC.onMail(office, new ValueMail!bool(1, true)); // This would end up calling "onSomeEvent"
        myC.onMail(office, new CommandMail(400));        // This would end up calling "onOtherEvent"
        assert(myC.eventCalled);
    }
}

/++
 + A UDA to be attached to a function.
 + 
 + Please see `IPostBox.generateOnMail` for a proper description on how to use this UDA.
 + ++/
struct MailBox
{
    /// The type of `Mail` this function should map to.
    Mail.MailTypeT type;
}

/++
 + The post office is where classes may subscribe (and unsubscribe) to certain types of messages, as well as post
 + mail to the office, alerting any subscribers of the mail.
 + 
 + It is essentially an event dispatcher, just with a fancy (stupid) name.
 + 
 + Memory_And_GC:
 +  `Mallocator` is used internally by the class, and most of the functions do not require the GC (by themselves, since
 +  functions such as `PostOffice.mail` will call user-passed functions, so @nogc cannot be used. Lambdas may also be
 +  GC-allocated when given to the PostOffice.).
 + 
 +  So overall, this class is suitable to be used with or without the GC. (I cannot confirm, but some of std.algorithm's
 +  functions seem to prevent @nogc in some cases, which should be noted).
 + ++/
final class PostOffice
{
    /++
     + The function type given when subscribing to a specific mail type.
     + 
     + Params:
     +  office = The `PostOffice` that is delivering the mail.
     +  mail   = The `Mail` that's been delievered.
     + ++/
    alias OnMailFunc = void delegate(PostOffice office, Mail mail);

    private
    {
        struct Subscriber
        {
            OnMailFunc      func;
            Mail.MailTypeT  type;
        }

        struct EnumRange
        {
            string         enumName;
            Mail.MailTypeT min;
            Mail.MailTypeT max;
        }

        Subscriber[] _subscribers;
        IPostBox[]   _postboxes;
        EnumRange[]  _reserved;
    }

    public
    {
        /++
         + Mails a message to any subscriber of the mail's `Mail.type`
         + 
         + Assertions:
         +  `mail` must not be `null`.
         + 
         + Params:
         +  mail = The mail to send.
         + ++/
        void mail(M : Mail)(M mail)
        {
            import std.algorithm : filter, each;
            assert(mail !is null, "The mail to send is null.");

            this._subscribers.filter!(s => s.type == mail.type)
                             .each  !(s => s.func(this, mail));

            this._postboxes.each!(p => p.onMail(this, mail));
        }
        ///
        unittest
        {
            enum Command : Mail.MailTypeT
            {
                IncrementI
            }

            int  i;
            auto office     = new PostOffice();
            auto subscriber = office.subscribe(Command.IncrementI, (office, mail) {i += 1;});
            office.reserveTypes!Command; // Not needed in this example, but I consider it good practice when using PostOffice to always do this.

            office.mailCommand(Command.IncrementI); // Same as: office.mail(new CommandMail(Command.IncrementI));
            assert(i == 1);
            office.mailCommand(Command.IncrementI);
            assert(i == 2);

            office.unsubscribe(subscriber);
            office.mailCommand(Command.IncrementI);
            assert(i == 2);
        }

        /++
         + Subscribes a delegate to a certain type of `Mail`.
         + 
         + Description:
         +  When a message that has the same `Mail.type` as `type` is mailed, then `onDeliver` is called.
         + 
         + Notes:
         +  $(P `onDeliver` $(B must) be used in `unsubscribe` before the host object is destroyed, otherwise it's very likely
         +      for a crash to occur.)
         +  $(P This function will return `onDeliver`, this is because if code such as `office.subscribe(0, (PostOffice p, Mail m) {})`
         +      is used, then there's no way to actually unsubscribe the lambda, since the calling code won't have any reference
         +      to it. Therefor `onDeliver` is returned so the calling code can store it for unsubscribing.)
         +  $(P For example - `auto lambda = office.subscribe(0, (PostOffice p, Mail m){}); /* Later on */ office.unsubscribe(lambda);`)
         + 
         + Assertions:
         +  `onDeliver` must not be `null`.
         + 
         + Params:
         +  type        = The type of mail to subscribe to.
         +  onDeliver   = The delegate to deliver any `Mail` of type `type` to.
         + 
         + Returns:
         +  `onDeliver`, see the Notes section as to why.
         + ++/
        @trusted
        OnMailFunc subscribe(Mail.MailTypeT type, OnMailFunc onDeliver)
        {
            assert(onDeliver !is null, "The delegate to subscribe to is null.");
            this._subscribers ~= Subscriber(onDeliver, type);

            return onDeliver;
        }
        ///
        unittest
        {
            import std.exception : assertThrown, enforce;

            enum Command : Mail.MailTypeT
            {
                EnsureEven
            }

            auto office = new PostOffice();
            office.reserveTypes!Command;
            auto lambda = office.subscribe(Command.EnsureEven, 
                                           (office, mail)
                                           {
                                               auto value = cast(ValueMail!int)mail;
                                               assert(value !is null);
                                               
                                               enforce(value.value % 2 == 0, "The value is not event");
                                           });
            scope(exit) office.unsubscribe(lambda);

            office.mailValue!int(Command.EnsureEven, 20); // `mailValue!int` is a helper function to mail a `ValueMail!int`
            office.mailValue!int(Command.EnsureEven, 50);

            assertThrown(office.mailValue!int(Command.EnsureEven, 59));
        }

        /++
         + Unsubscribes a delegate from all of the mail types it's subscribed to.
         + 
         + Assertions;
         +  $(P `onDeliver` must not be null.)
         +  $(P `onDeliver` must have been previously subscribed. It's technically harmless for it not to have been, but
         +      it's probably a sign of a bug in the caller's code.)
         + 
         + Params:
         +  onDeliver = The delegate to try to find and unsubscribe.
         + ++/
        @trusted
        void unsubscribe(OnMailFunc onDeliver)
        {
            import std.algorithm : countUntil;

            assert(onDeliver !is null, "The delegate to unsubscribe to is null.");

            auto result = this._subscribers.countUntil!"a.func == b"(onDeliver);
            assert(result != -1, "Attempted to unsubscribe a delegate that hasn't been subscribed yet.");

            this._subscribers.removeAt(result);
        }
        ///
        unittest
        {
            import std.exception : assertThrown, assertNotThrown;

            enum Command : Mail.MailTypeT
            {
                ThrowException
            }

            auto office = new PostOffice();
            office.reserveTypes!Command;
            auto lambda = office.subscribe(Command.ThrowException, (off, mail) {throw new Exception("");});

            assertThrown(office.mailCommand(Command.ThrowException));
            office.unsubscribe(lambda);
            assertNotThrown(office.mailCommand(Command.ThrowException));
        }

        /++
         + Subscribes a postbox to listen to any `Mail` that is posted to the `PostOffice`.
         + 
         + Description:
         +  Anytime a `Mail` is mailed to a `PostOffice`, the mail is first sent to any specific subscribers of the function,
         +  (see the overload that takes an `OnMailFunc`) and is then sent to every `IPostBox` that is subscribed.
         + 
         + Assertions:
         +  `postBox` must not be `null`.
         + 
         + Params:
         +  postBox = The `IPostBox` to subscribe.
         + 
         + See_Also:
         +  `IPostBox.generateOnMail`
         + 
         + Returns:
         +  `postBox`
         + ++/
        @trusted
        IPostBox subscribe(IPostBox postBox)
        {
            assert(postBox !is null, "The postbox to subscribe is null.");
            this._postboxes ~= postBox;

            return postBox;
        }
        ///
        unittest
        {
            import std.exception : assertThrown, assertNotThrown, enforce;

            enum Command : Mail.MailTypeT
            {
                CheckIfTrue
            }

            static class C : IPostBox
            {
                mixin(IPostBox.generateOnMail!C);

                @MailBox(Command.CheckIfTrue)
                void check(PostOffice, ValueMail!bool mail)
                {
                    enforce(mail.value);
                }
            }

            auto office = new PostOffice();
            office.reserveTypes!Command;
            auto object = office.subscribe(new C());

            assertNotThrown(office.mailValue(Command.CheckIfTrue, true));
            assertThrown   (office.mailValue(Command.CheckIfTrue, false));
            office.unsubscribe(object);
            assertNotThrown(office.mailValue(Command.CheckIfTrue, false));
        }

        /++
         + Unsubscribes a postbox from listening to any `Mail`.
         + 
         + Assertions:
         +  $(P `postBox` must not be null.)
         +  $(P `postBox` must have been previously subscribed. It is deemed a bug in the caller's code if this function
         +      is called on an non-subscribed `IPostBox`.)
         + 
         + Params:
         +  postBox = The `IPostBox` to unsubscribe.
         + ++/
        @trusted
        void unsubscribe(IPostBox postBox)
        {
            import std.algorithm : countUntil;
            assert(postBox !is null, "The postbox to unsubscribe is null.");

            auto result = this._postboxes.countUntil(postBox);
            assert(result != -1, "Attempted to unsubscribe a postbox that hasn't been subscribed yet.");
            
            this._postboxes.removeAt(result);
        }
        ///
        unittest
        {
            import std.exception : assertThrown, assertNotThrown;

            enum Command : Mail.MailTypeT
            {
                Exception
            }

            class C : IPostBox
            {
                mixin(IPostBox.generateOnMail!C);

                @MailBox(Command.Exception)
                void throwException(PostOffice, Mail mail)
                {
                    throw new Exception("");
                }
            }

            auto office = new PostOffice();
            office.reserveTypes!Command;
            auto object = office.subscribe(new C());

            assertThrown(office.mailCommand(Command.Exception));
            office.unsubscribe(object);
            assertNotThrown(office.mailCommand(Command.Exception));
        }

        /++
         + Determines if a certain `OnMailFunc`/`IPostBox` is subscribed.
         + 
         + Params:
         +  subscriber = The `OnMailFunc`/`IPostBox` to look for.
         + 
         + Returns:
         +  `true` if `subscriber` has been subscribed.
         +  `false` if `subscriber` has not been subscribed.
         + ++/
        @safe @nogc
        bool isSubscribed(OnMailFunc subscriber) nothrow const
        {
            import std.algorithm : canFind;
            return this._subscribers.canFind!(s => s.func == subscriber);
        }
        ///
        unittest
        {
            auto office = new PostOffice();
            auto lambda = office.subscribe(0, (office, mail) {});

            assert(office.isSubscribed(lambda));
            office.unsubscribe(lambda);
            assert(!office.isSubscribed(lambda));
        }

        /// Ditto
        @trusted
        bool isSubscribed(IPostBox subscriber) const
        {
            import std.algorithm : canFind;
            return this._postboxes.canFind!(po => po == subscriber);
        }
        ///
        unittest
        {
            class P : IPostBox
            {
                void onMail(PostOffice, Mail) {}
            }

            auto office = new PostOffice();
            auto box    = office.subscribe(new P());

            assert(office.isSubscribed(box));
            office.unsubscribe(box);
            assert(!office.isSubscribed(box));
        }

        /++
         + Given an enum, a check is made to make sure every value in the enum hasn't be reserved yet.
         + 
         + Assertions:
         +  $(P Every value in `E` must have not been included in any previous enum passed to this function.)
         +  $(P `E` must follow a standard pattern of `enum E {A = 1, B = 2, C = 3, etc...}` where the next enum value
         +      is, `next = previous + 1`)
         + 
         + Description:
         +  Because the type of a `Mail` can be designed so there are multiple enums (e.g `enum WindowMailTypes`,
         +  `enum SceneMailTypes` etc.) this function can be used to make sure there are no conflics between any
         +  other `enum`s that are planned to be used with this office.
         + 
         +  It is basically a way to enforce no conflicts between different enums of `Mail` types.
         + 
         +  If `E` has been passed to this function already, then this function simply returns.
         + ++/
        @trusted
        void reserveTypes(E)()
        if(is(E == enum))
        {
            import std.traits    : EnumMembers, fullyQualifiedName;
            import std.algorithm : canFind;
            enum members = EnumMembers!E;
            static assert(is(typeof(members[0]) : Mail.MailTypeT), "The members of "~E.stringof~" are not implicitly convertable to "~Mail.MailTypeT.stringof);

            foreach(i, member; members)
            {
                static if(i == 0)
                    continue;
                else
                    static assert(cast(Mail.MailTypeT)member == cast(Mail.MailTypeT)(members[i - 1] + 1),
                                  "The members of " ~ E.stringof ~ " are not formatted correctly. Offender = " ~ member.stringof);
            }

            // First, see if the enum has already been reserved.
            auto name = fullyQualifiedName!E;
            if(this._reserved.canFind!((r) => r.enumName == name))
                return;

            // Otherwise, make sure its members are non-reserved.
            auto range = EnumRange(name, E.min, E.max);
            foreach(reserved; this._reserved)
            {
                bool fail = false;
                if(range.min    >= reserved.min && range.min    <= reserved.max) fail = true;
                if(range.max    >= reserved.min && range.max    <= reserved.max) fail = true;
                if(reserved.max >= range.min    && reserved.max <= range.max)    fail = true;
                if(reserved.min >= range.min    && reserved.min <= range.max)    fail = true;

                assert(!fail, "The enum " ~ E.stringof ~ " is causing a conflict.");
            }

            this._reserved ~= range;
        }
        ///
        unittest
        {
            enum A : Mail.MailTypeT
            {
                A = 0,
                B = 1,
                C = 2
            }

            enum B : Mail.MailTypeT
            {
                A = 4,
                B = 5,
                C = 6
            }

            enum C : Mail.MailTypeT
            {
                A = 3,
                B = 4
            }

            auto office = new PostOffice();
            office.reserveTypes!A; // Fine, no conflicts
            office.reserveTypes!B; // Fine, no conflicts
            //office.reserveTypes!C; // Not fine, conflicts with B
            office.reserveTypes!A; // Fine, A has been reserved already
        }
    }
}
///
unittest
{
    enum Command : Mail.MailTypeT
    {
        CheckIfTrue = 1,
        SetFlag     = 2
    }

    static class C : IPostBox
    {
        mixin(IPostBox.generateOnMail!C);

        @MailBox(Command.CheckIfTrue)
        void checkTrue(PostOffice, ValueMail!bool mail)
        {
            assert(mail.value);
        }
    }

    // Alternatively, using a custom-made "onMail" function.
    auto alternateClass = 
    q{
        static class AlternateC : IPostBox
        {
            void onMail(PostOffice office, Mail mail)
            {
                if(mail.type == Command.CheckIfTrue)
                {
                    auto value = cast(ValueMail!bool)mail;
                    assert(value.value);
                }
            }
        }
    };

    bool flag = false;
    void setFlag(PostOffice, Mail)
    {
        flag = true;
    }

    auto office = new PostOffice();
    auto myC    = new C();
    office.reserveTypes!Command;
    office.subscribe(myC);
    office.subscribe(Command.SetFlag, &setFlag);

    assert(!flag);
    office.mailCommand(Command.SetFlag);
    assert(flag);

    office.mailValue!bool(Command.CheckIfTrue, true);

    assert(office.isSubscribed(&setFlag));
    office.unsubscribe(&setFlag);
    assert(!office.isSubscribed(&setFlag));

    assert(office.isSubscribed(myC));
    office.unsubscribe(myC);
    assert(!office.isSubscribed(myC));
}

/++
 + The most basic mail, all it does is simply hold a `Mail.MailTypeT`.
 + 
 + This is useful for simply mailing a command (CloseWindow, StopGameLoop, etc.) to anything that is subscribed.
 + 
 + A helper function, `mailCommand`, is provided to easily send mail of this type.
 + ++/
class CommandMail : Mail
{
    public
    {
        /++
         + Creates a new CommandMail.
         + 
         + Params:
         +  command = The command to attach to the mail.
         + ++/
        @safe @nogc
        this(Mail.MailTypeT command) nothrow
        {
            super(command);
        }
    }
}

/++
 + Convinience function to mail a `CommandMail`.
 + 
 + Allocation:
 +  This function uses `Mallocator` to allocate it's message, and the message is disposed of as soon as
 +  the function exits.
 + 
 + Params:
 +  office  = The `PostOffice` to mail to.
 +  command = The command to mail.
 + ++/
void mailCommand(PostOffice office, Mail.MailTypeT command)
{
    auto mail = Mallocator.instance.make!CommandMail(command);
    scope(exit) Mallocator.instance.dispose(mail);

    office.mail(mail);
}
///
unittest
{
    auto office = new PostOffice();
    auto lambda = office.subscribe(20, (office, mail) 
                                       {
                                           assert(cast(CommandMail)mail !is null);
                                       });
    office.mailCommand(20);
}

/++
 + A step up from `CommandMail`. A value mail is used to mail both a command, as well as a value.
 + 
 + For example, `office.mail(new ValueMail(Commands.Set_Window_Size, Vector2f(200, 400)))`
 + 
 + A helper function, `mailValue`, is provided to easily mail a `ValueMail`.
 + 
 + Params:
 +  T = The type used as the mail's value.
 + ++/
class ValueMail(T) : Mail
{
    public
    {
        /// The value of the mail.
        T value;

        /++
         + Creates a new ValueMail.
         + 
         + Params:
         +  command = The command of the mail.
         +  value   = The value of the mail.
         + ++/
        this(Mail.MailTypeT command, T value)
        {
            super(command);
            this.value = value;
        }
    }
}

/++
 + Convinience function to mail a `ValueMail`.
 + 
 + Allocation:
 +  This function uses `Mallocator` to allocate the message, which is then disposed of when the function exits.
 + 
 + Params:
 +  office  = The office to mail to.
 +  command = The command to mail.
 +  value   = The value to mail.
 + ++/
void mailValue(T)(PostOffice office, Mail.MailTypeT command, T value)
{
    alias Mail = ValueMail!T;
    auto  mail = Mallocator.instance.make!Mail(command, value);
    scope(exit)  Mallocator.instance.dispose(mail);

    office.mail(mail);
}
///
unittest
{
    enum Command : Mail.MailTypeT
    {
        AddToNum
    }

    int num = 0;
    auto office = new PostOffice();
    office.reserveTypes!Command;

    office.subscribe(Command.AddToNum, 
                    (office, mail)
                    {
                        auto value = cast(ValueMail!int)mail;
                        num += value.value;
                    });

    assert(num == 0);
    office.mailValue!int(Command.AddToNum, 20);
    assert(num == 20);
    office.mailValue!int(Command.AddToNum, 80);
    assert(num == 100);
}

// Some strange code I made for whatever reason (original: jaster.algorithm)

import std.range : isRandomAccessRange, ElementType;

/++
 + Determines the behaviour of `removeAt`.
 + ++/
enum RemovePolicy
{
    /++
     + Replaces the element at the given index with the last element in the range.
     +
     + Faster than moveRight, but can leave things out of order.
     + Also reduces the range's length by 1.
     + ++/
    moveLast,

    /++
     + Moves every element that is to the right of the element in the given index, to
     + the left by 1 space.
     +
     + Slower than moveLast, but will preserve the order of elements.
     + Also reduces the range's length by 1.
     + ++/
    moveRight,

    /++
     + Replaces the element at the given index with a default value.
     +
     + If the element is a class, `null` is used.
     + Otherwise, `ElementType.init` is used.
     +
     + Doesn't alter the length of the range, but does leave a possibly unwanted value.
     + ++/
    defaultify
}

/++
 + Removes an element at a given index.
 +
 + Params:
 +  range  = The RandomAccessRange to remove the element from.
 +  index  = The index of the element to remove.
 +  policy = What behaviour the function should use to remove the element.
 +
 + Returns:
 +  `range`
 + ++/
Range removeAt(Range)(auto ref Range range, size_t index, RemovePolicy policy = RemovePolicy.moveRight)
if(isRandomAccessRange!Range)
{
    assert(index < range.length);

    // Built-in arrays don't support .popBack
    // User-made RandomAccessRanges do
    // So this function just chooses the right one.
    void popBack()
    {
        static if(is(typeof({Range r; r.popBack();})))
            range.popBack();
        else static if(is(typeof({Range r; r.length -= 1;})))
            range.length -= 1;
        else
            static assert(false, "Type '" ~ Range.stringof ~ "' does not support a way of shortening it's length");
    }

    alias ElementT    = ElementType!Range;
    const isLastIndex = (index == range.length);

    final switch(policy) with(RemovePolicy)
    {
        case defaultify:
            static if(is(ElementT == class))
                ElementT value = null;
            else
                ElementT value = ElementT.init;

            range[index] = value;
            break;

        case moveLast:
            if(!isLastIndex)
                range[index] = range[$ - 1];

            popBack();
            break;

        case moveRight:
            if(!isLastIndex)
            {
                for(size_t i = index + 1; i < range.length; i++)
                {
                    if(i == 0) continue;

                    range[i - 1] = range[i];
                }
            }

            popBack();
            break;
    }

    return range;
}
///
unittest
{
    import std.array;
    assert([0, 1, 2, 3, 4, 5].removeAt(2, RemovePolicy.moveLast)   == [0, 1, 5, 3, 4]);
    assert([0, 1, 2, 3, 4, 5].removeAt(2, RemovePolicy.moveRight)  == [0, 1, 3, 4, 5]);
    assert([0, 1, 2, 3, 4, 5].removeAt(2, RemovePolicy.defaultify) == [0, 1, 0, 3, 4, 5]);
}