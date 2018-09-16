///
module jarena.core.interfaces;

private
{
    import std.typecons : Flag;
}

alias ScheduledDispose = Flag!"scheduledDispose";

/++
 + This interface describes an object that supports being able to dispose of it's underlying data.
 +
 + This is useful for classes such as Textures, or file handles, where it may be useful to be able to
 + allow the code to unload it's data when it is no longer needed, without actually destroying to object.
 +
 + There is no defined behaviour for when an object is accessed after it has been disposed. If needed, it is
 + recommended the object defines this in their documentation and any relevent functions.
 +
 + Some objects may need to wait until a certain moment before they can be disposed. For example, Textures may want
 + to wait until the end of the frame before disposing, as they could already expected to be valid textures by the rendering for the current frame.
 + Objects such as this will want to turn towards the `Systems.shortTermScheduler` system, as it provides the utilities for this.
 + ++/
interface IDisposable
{
    /++
     + Disposes of the object's underlying data.
     +
     + If the object is already disposed, unless it makes sense to fail an assert or throw an exception,
     + this function should be no-op.
     +
     + Params:
     +  scheduled = Whether this function was called by the `Systems.shortTermScheduler` system or not.
     +              This should always be `false` for user code. Implementations are free to ignore this parameters
     +              if they do not perform a scheduled dispose.
     + ++/
    void dispose(ScheduledDispose scheduled = ScheduledDispose.no);

    /++
     + Code should make sure to always check this function before doing anything with an IDisposable object.
     +
     + Returns:
     +  Whether this object's data has been disposed or not.
     + ++/
     @property
     bool isDisposed();
}