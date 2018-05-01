/// Contains the core classes relating to using the audio system.
///
/// Publically imports `std.typecons.Yes` and `std.typecons.No` as some of the functions make use of `std.typecons.Flag`
module jarena.audio.audio;

private
{
    import std.experimental.logger;
    import std.typecons : Flag;
    import derelict.sdl2.mixer;
    import derelict.fmod.fmod;
    import jarena.core;

    enum MAX_CHANNELS = 64;
    enum FMOD_FLAGS   = FMOD_INIT_THREAD_UNSAFE; // Remove THREAD_UNSAFE if we start to use sounds across multiple threads.
}

public import std.typecons : Yes, No;

/++
 +
 + ++/
struct Channel
{
    private FMOD_CHANNEL* handle;
}

/++
 + Contains a sound.
 +
 + There are two types of sounds, 'normal', and 'streaming' sounds.
 +
 + Normal sounds have their entire audio data loaded into memory.
 +
 + Streaming sounds have their audio data streamed from the disk in chunks.
 + There is also a limitation that only a single streaming sound can be played at one time.
 + ++/
final class Sound
{
    private final
    {
        FMOD_SOUND* _handle;

        pragma(inline, true)
        @safe @nogc
        inout(FMOD_SOUND*) handle() nothrow pure inout
        {
            return this._handle;
        }
    }

    public final
    {
        this(const char[] filePath, Flag!"streaming" streaming = No.streaming)
        {
            import std.exception : enforce;
            import std.file      : exists;
            import std.string    : toStringz;

            infof("Loading in %ssound from '%s'", (streaming) ? "streaming " : "", filePath);
            enforce(filePath.exists, "Unable to load file as it does not exist.");
            
            auto manager = Systems.audio; // There is no need (And no support) for multiple audio managers.
            auto flags   = (streaming) ? FMOD_CREATESTREAM : FMOD_DEFAULT;
            auto result  = FMOD_System_CreateSound(manager.fmodHandle, filePath.toStringz, flags, null, &this._handle);
            if(result != FMOD_OK)
                fatalf("FMOD was unable to create the sound: %s", FMOD_ErrorString(result));
        }
    }
}

///
final class AudioManager
{
    private final
    {
        FMOD_SYSTEM* _fmod;

        pragma(inline, true)
        @safe @nogc
        inout(FMOD_SYSTEM*) fmodHandle() nothrow pure inout
        {
            return this._fmod;
        }
    }

    public final
    {
        this()
        {
            trace("Initialising the Audio Manager");

            auto result = FMOD_System_Create(&this._fmod);
            if(result != FMOD_OK)
                fatalf("FMOD_System_Create failed: %s", FMOD_ErrorString(result));

            result = FMOD_System_Init(this.fmodHandle, MAX_CHANNELS, FMOD_FLAGS, null);
            if(result != FMOD_OK)
                fatalf("FMOD_System_Init failed: %s", FMOD_ErrorString(result));
        }

        ~this()
        {
            FMOD_System_Release(this.fmodHandle);
        }

        Channel play(Sound sample)
        {
            assert(sample !is null);
            
            Channel channel;
            auto result = FMOD_System_PlaySound(this.fmodHandle, sample.handle, null, false, &channel.handle);
            if(result != FMOD_OK && result != FMOD_ERR_TOOMANYCHANNELS)
                fatalf("Unable to play sound: %s", FMOD_ErrorString(result));

            return channel;
        }

        void onUpdate()
        {
            FMOD_System_Update(this.fmodHandle);
        }
    }
}