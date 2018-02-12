module jarena.core.time;

private
{
    import derelict.sfml2.system;
}

///
struct GameTime
{
    public
    {
        ///
        sfTime handle;

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
        @trusted @nogc
        float asSeconds() nothrow const
        {
            return sfTime_asSeconds(this.handle);
        }

        ///
        @trusted @nogc
        int asMilliseconds() nothrow const
        {
            return sfTime_asMilliseconds(this.handle);
        }

        ///
        @trusted @nogc
        long asMicroseconds() nothrow const
        {
            return sfTime_asMicroseconds(this.handle);
        }
    }
}

///
class Clock
{
    private
    {
        sfClock* _handle;

        @property @safe @nogc
        inout(sfClock*) handle() nothrow inout
        {
            assert(this._handle !is null);
            return this._handle;
        }
    }

    public
    {
        ///
        @trusted @nogc
        this() nothrow
        {
            this._handle = sfClock_create();
        }

        ~this()
        {
            if(this._handle !is null)
                sfClock_destroy(this.handle);
        }

        ///
        @trusted @nogc
        GameTime getElapsedTime() nothrow const
        {
            return GameTime(sfClock_getElapsedTime(this.handle));
        }

        ///
        @trusted @nogc
        GameTime restart() nothrow
        {
            return GameTime(sfClock_restart(this.handle));
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
                this._elapsedSeconds = 0;
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