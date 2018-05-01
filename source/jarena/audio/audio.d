/// Contains the core classes relating to using the audio system.
///
/// Publically imports `std.typecons.Yes` and `std.typecons.No` as some of the functions make use of `std.typecons.Flag`
module jarena.audio.audio;

private
{
    import std.experimental.logger;
    import std.typecons : Flag;
    import derelict.sdl2.mixer;
    import jarena.core;
}

public import std.typecons : Yes, No;

/++
 + Contains an audio sample.
 + ++/
final class Sample
{
    private final
    {
        Mix_Chunk* _handle;
        int        _volume;

        @safe @nogc
        inout(Mix_Chunk*) handle() nothrow inout pure
        {
            assert(this._handle !is null, "Attempted to use a null handle");
            return this._handle;
        }
    }

    public final
    {
        ///
        enum MAX_VOLUME = MIX_MAX_VOLUME;

        ///
        this(const(char)[] filePath)
        {
            import std.string : toStringz;
            tracef("Loading audio sample from path '%s'", filePath);
            this._handle = Mix_LoadWAV(filePath.toStringz);
            checkSDLError();
            enforceAndLogf(this._handle !is null, "Unable to load sound file at '%s'", filePath);

            this._volume = Mix_VolumeChunk(this.handle, -1); // Acts as a getter when given a negative value.
        }
        
        ~this()
        {
            if(this._handle !is null)
                Mix_FreeChunk(this.handle);
        }

        /// Between 0 and 128.
        @property @safe @nogc
        int volume() nothrow pure const
        {
            return this._volume;
        }

        ///
        @property @safe @nogc
        void volume(int value) nothrow pure
        {
            this._volume = value;
        }
    }
}

///
struct Channel
{
    private const int id;
}

///
final class AudioManager
{
    private final
    {
        int _channelCount;
        ChannelGroup[string] _groups;
        ChannelGroup[]       _groupIDMap; // A map between ChannelID -> Group
                                          // Uses a decent amount of memory space though...

        void allocateChannels(int amount)
        {
            infof("Allocating %s channels", amount);
            this._channelCount = Mix_AllocateChannels(amount);

            if(amount >= 0)
                this._groupIDMap.length = amount;
        }

        void regroupChannels()
        {
            trace("Regrouping audio channels.");

            // Ungroup all channels.
            Mix_GroupChannels(0, this._channelCount, -1); // -1 = Default

            // Make sure we have the right amount of channels
            auto channelCount = 0;
            foreach(value; this._groups.byValue)
                channelCount += value._channelCount;

            if(channelCount > this._channelCount)
                this.allocateChannels(channelCount);

            Mix_ReserveChannels(channelCount);
            this._groupIDMap[] = null;

            // Then assign the channels to their groups.
            int lastEnd = 0;
            foreach(key; this._groups.byKey) // We have to use byKey, since byValue returns a const reference.
            {
                auto group = this._groups[key];
                if(group._channelCount < 1)
                    continue;

                group._firstChannelId = lastEnd;
                auto startChannel = group.offsetChannelID(0);
                auto endChannel   = group.offsetChannelID(group._channelCount - 1); // Mix_GroupChannels uses an inclusive upper-bound T.T
                auto count        = Mix_GroupChannels(startChannel, endChannel, group._groupId);

                infof("Audio group '%s' was given the channels %s..%s", key, startChannel, endChannel);

                lastEnd = endChannel + 1;
                if(count != group._channelCount)
                    assert(false, "Bug");

                this._groupIDMap[startChannel..endChannel+1][] = group;
            }
        }
    }

    public final
    {
        ///
        ChannelGroup makeGroup(string name, int channelCount)
        {
            tracef("Creating audio group called '%s' with %s channels.", name, channelCount);

            if((name in this._groups) !is null)
                assert(false, "The group '"~name~"' already exists.");

            auto group = new ChannelGroup(this, channelCount);
            this._groups[name] = group;

            this.regroupChannels();
            return group;
        }

        /// Returns: `null` if the group doesn't exist
        @safe @nogc
        inout(ChannelGroup) getGroup(string name) nothrow inout
        {
            auto ptr = (name in this._groups);
            return (ptr is null) ? null : *ptr;
        }
    }
}

///
final class ChannelGroup
{
    private final
    {
        AudioManager _manager;
        int _channelCount;
        int _firstChannelId;
        int _groupId;

        @safe @nogc
        int offsetChannelID(int relativeId) nothrow pure const
        {
            return (this._firstChannelId + relativeId);
        }

        @safe @nogc
        this(AudioManager manager, int channelCount) nothrow
        {
            assert(manager !is null);
            this._manager = manager;
            this._channelCount = channelCount;
        }
    }

    public final
    {
        // TODO: Extend this a bunch
        bool play(Sample sample, Flag!"useOldest" overwriteOldest = Yes.useOldest)
        {
            assert(sample !is null);

            auto channel = this.nextUnused();
            if(channel.id >= 0)
            {
                Mix_PlayChannel(channel.id, sample.handle, 0);
                return true;
            }

            // No unused channel was found so use the oldest-accessed channel that's currently playing.
            auto oldest = this.oldestUsed;
            if(overwriteOldest && oldest.id >= 0)
            {
                Mix_ExpireChannel(oldest.id, 0);
                Mix_PlayChannel(oldest.id, sample.handle, 0);
                return true;
            }

            // No unsused channels, and no oldest channels (aka, the group is empty)
            return false;
        }

        ///
        @nogc
        const(Channel) nextUnused() nothrow const
        {
            return Channel(Mix_GroupAvailable(this._groupId));
        }

        ///
        @nogc
        const(Channel) oldestUsed() nothrow const
        {
            return Channel(Mix_GroupOldest(this._groupId));
        }
    }
}