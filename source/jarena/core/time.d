///
module jarena.core.time;

///
alias TimerFunc = void delegate();

///
struct GameTime
{
    public
    {
        ///
        //sfTime handle;

        ///
        @safe
        string toString() nothrow const
        {
            import std.exception : assumeWontThrow;
            import std.format    : format;

            return format("GameTime(%s seconds, %s ms, %s microseconds)", 
                          this.asSeconds, this.asMilliseconds, this.asMicroseconds).assumeWontThrow;
        }

        ///
        @trusted
        static GameTime fromSeconds(float seconds)
        {
            GameTime time;
            //time.handle = sfSeconds(seconds);

            return time;
        }

        ///
        @trusted
        static GameTime fromMilliseconds(int ms)
        {
            GameTime time;
            //time.handle = sfMilliseconds(ms);

            return time;
        }

        ///
        @trusted
        static GameTime fromMicroseconds(long micro)
        {
            GameTime time;
            //time.handle.microseconds = micro;

            return time;
        }

        ///
        @trusted @nogc
        float asSeconds() nothrow const
        {
            return 0;
        }

        ///
        @trusted @nogc
        int asMilliseconds() nothrow const
        {
            return 0;
        }

        ///
        @safe @nogc
        long asMicroseconds() nothrow const
        {
            return 0;
        }

        GameTime opBinary(string op)(GameTime rhs)
        {
            return rhs;
            //return mixin("GameTime(sfTime(this.handle.microseconds "~op~" rhs.handle.microseconds))");
        }

        void opOpAssign(string op)(GameTime rhs)
        {
            //mixin("this = this "~op~" rhs;");
        }
    }
}

///
class Clock
{
    private
    {
        //sfClock* _handle;
    }

    public
    {
        ///
        @trusted @nogc
        this() nothrow
        {
            //this._handle = sfClock_create();
        }

        ///
        @trusted @nogc
        GameTime getElapsedTime() nothrow const
        {
            return GameTime();
            //return GameTime(sfClock_getElapsedTime(this.handle));
        }

        ///
        @trusted @nogc
        GameTime restart() nothrow
        {
            return GameTime();
            //return GameTime(sfClock_restart(this.handle));
        }
    }
}

/++
 + Repeatedly sends a given `Mail` to a PostOffice after a delay.
 +
 + This class is useful for subscribing a certain kind of event to a post office, such as "apply Death to Daniel",
 + and then having that event fire off every 2 seconds, for example.
 + ++/
class MailTimer
{
    import jarena.core.post;

    private
    {
        PostOffice  _office;
        Mail        _mail;
        GameTime    _delay;
        GameTime    _current;
        bool        _isStopped;
    }

    public
    {
        /++
         + Params:
         +  office = The `PostOffice` to send the mail to.
         +  mail   = The `Mail` to send. This mail won't be changed (inside of this class at least) between repeated maililngs.
         +  delay  = A `GameTime` which specifies the delay between each mailing.
         + ++/
        @safe @nogc
        this(PostOffice office, Mail mail, GameTime delay) nothrow pure
        {
            assert(office !is null);
            assert(mail !is null);

            this._office = office;
            this._mail = mail;
            this._delay = delay;
        }

        ///
        void onUpdate(GameTime deltaTime)
        {
            if(this._isStopped)
                return;

            this._current += deltaTime;
            if(this._current.asMicroseconds >= this._delay.asMicroseconds)
            {
                this._office.mail(this._mail);
                this._current = GameTime();
            }
        }

        ///
        void stop()
        {
            this._isStopped = true;
        }

        ///
        void start()
        {
            this._isStopped = false;
        }

        ///
        void restart()
        {
            this.start();
            this._delay = GameTime();
        }
    }
}

class Timers
{
    alias TimerEvent = void delegate();

    private
    {
        struct After
        {
            GameTime delay;
            GameTime lastUpdateTime;
            TimerEvent func;
        }

        alias Every = After; // To make the different yet similar code more understandable.

        After[] _after;
        Every[] _every;
        GameTime _currentTime;
    }

    public
    {
        /++
         + After a certain delay, execute a function once.
         +
         + Params:
         +  delay = The delay until the function is executed.
         +  func = The function to execute.
         + ++/
        @safe
        void after(GameTime delay, TimerEvent func) nothrow
        {
            this._after ~= After(delay, this._currentTime, func);
        }

        /++
         + Every `delay`, execute a function.
         +
         + Params:
         +  delay = The delay between every execution.
         +  func = The function to execute.
         + ++/
        @safe
        void every(GameTime delay, TimerEvent func) nothrow
        {
            this._every ~= Every(delay, this._currentTime, func);
        }

        ///
        void onUpdate(GameTime deltaTime)
        {
            this._currentTime += deltaTime;

            bool processEvent(ref After event)
            {
                auto elapsed = (this._currentTime.asMicroseconds - event.lastUpdateTime.asMicroseconds);
                if(elapsed >= event.delay.asMicroseconds)
                {
                    event.lastUpdateTime = this._currentTime;
                    event.func();
                    return true;
                }

                return false;
            }

            for(size_t i = 0; i < this._after.length; i++)
            {
                auto eventCalled = processEvent(this._after[i]);
                if(eventCalled)
                {
                    import std.algorithm    : countUntil;
                    import jarena.core.post : removeAt;
                    this._after.removeAt(this._after.countUntil!"a.func == b.func"(this._after[i]));
                    i--;
                }
            }
            
            foreach(ref every; this._every)
                processEvent(every); // TODO: Add a function to remove .every events
        }
    }
}

///
class FPS
{
    private
    {
        Clock _clock;
        GameTime _previousFrame;
        float _elapsedSeconds;
        uint _frameCountPrevious;
        uint _frameCount;
    }

    public
    {
        ///
        this()
        {
            this._clock = new Clock();
            this._elapsedSeconds = 0;
        }

        ///
        void onUpdate()
        {
            this._previousFrame = this._clock.restart();
            this._elapsedSeconds += this._previousFrame.asSeconds;

            this._frameCount++;
            if(this._elapsedSeconds >= 1)
            {
                this._frameCountPrevious = this._frameCount;
                this._frameCount = 0;
                this._elapsedSeconds -= 1; // So we don't knock off any of the decimal time, making it more accurate.
            }
        }

        ///
        @property @safe @nogc
        uint frameCount() nothrow const
        {
            return this._frameCountPrevious;
        }

        ///
        @property @safe @nogc
        GameTime elapsedTime() nothrow const
        {
            return this._previousFrame;
        }
    }
}
