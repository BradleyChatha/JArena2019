///
module jarena.core.time;

public import core.time;

/++
 + Converts a duration into seconds.
 +
 + Notes:
 +  This is preferred over using `myDuration.total!"seconds"` as this function will provide
 +  a float form of the number, whereas `total` seems to round it to the nearest second.
 + ++/
float asSeconds()(Duration dur)
{
    return (cast(float)dur.total!"usecs" / 1_000_000.0f);
}

///
alias TimerFunc = void delegate();

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
        Duration    _delay;
        Duration    _current;
        bool        _isStopped;
    }

    public
    {
        /++
         + Params:
         +  office = The `PostOffice` to send the mail to.
         +  mail   = The `Mail` to send. This mail won't be changed (inside of this class at least) between repeated maililngs.
         +  delay  = A `Duration` which specifies the delay between each mailing.
         + ++/
        @safe @nogc
        this(PostOffice office, Mail mail, Duration delay) nothrow pure
        {
            assert(office !is null);
            assert(mail !is null);

            this._office = office;
            this._mail = mail;
            this._delay = delay;
        }

        ///
        void onUpdate(Duration deltaTime)
        {
            if(this._isStopped)
                return;

            this._current += deltaTime;
            if(this._current >= this._delay)
            {
                this._office.mail(this._mail);
                this._current = Duration();
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
            this._delay = Duration();
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
            Duration delay;
            Duration lastUpdateTime;
            TimerEvent func;
        }

        alias Every = After; // To make the different yet similar code more understandable.

        After[] _after;
        Every[] _every;
        Duration _currentTime;
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
        void after(Duration delay, TimerEvent func) nothrow
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
        void every(Duration delay, TimerEvent func) nothrow
        {
            this._every ~= Every(delay, this._currentTime, func);
        }

        ///
        void onUpdate(Duration deltaTime)
        {
            this._currentTime += deltaTime;
            
            bool processEvent(ref After event)
            {
                auto elapsed = (this._currentTime - event.lastUpdateTime);
                if(elapsed >= event.delay)
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
        MonoTime _previousFrame;
        Duration _elapsedTime;
        float _elapsedSeconds;
        uint _frameCountPrevious;
        uint _frameCount;
    }

    public
    {
        ///
        this()
        {
            this._elapsedSeconds = 0;
            this._previousFrame = MonoTime.currTime;
        }

        ///
        void onUpdate()
        {
            this._elapsedTime = (MonoTime.currTime - this._previousFrame);
            this._elapsedSeconds += this.elapsedTime.asSeconds;
            this._previousFrame = MonoTime.currTime;
            
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
        Duration elapsedTime() nothrow const
        {
            return this._elapsedTime;
        }
    }
}
