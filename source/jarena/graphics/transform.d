module jarena.graphics.transform;

private
{
    import jarena.core, jarena.graphics;
    import opengl;
}

struct Transform
{
    private
    {
        mat4 _matrix;
        vec2 _translation = vec2(0);

        bool _dirty = true;
    }

    public
    {
        /++
         + Notes:
         +  Can basically imagine as the position.
         +
         + Returns:
         +  The translation of this transformation.
         + ++/
        @safe @nogc
        ref inout(vec2) translation() nothrow pure inout
        {
            return this._translation;
        }
        
        /++
         + Notes:
         +  Even though a ref is returned, it's recommended to _not_ modify the matrix.
         +
         +  The ref is just so there aren't a bunch of floats constantly being copied around.
         +
         + Returns:
         +  A matrix containing all of the transformations specified by this struct.
         + ++/
        @property @safe @nogc
        ref mat4 matrix() nothrow
        {
            if(this._dirty)
            {
                this._matrix = mat4.identity;
                // this._matrix.scale(...);
                // this._matrix.rotate(...);
                this._matrix.translate(this._translation.x, this._translation.y, 0);

                this._dirty = false;
            }
            
            return this._matrix;
        }
    }
}
