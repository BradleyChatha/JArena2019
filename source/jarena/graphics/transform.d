/++
 + Contains anything related to transformations.
 + ++/
module jarena.graphics.transform;

private
{
    import jarena.core, jarena.graphics;
    import opengl;
}

/// The common interface for any object that can be transformed.
interface ITransformable
{
    public
    {
        /++
         + Sets the position of the transformable object.
         +
         + Params:
         +  pos = The position to set the object at.
         + ++/
        @property @safe @nogc
        void position(vec2 pos) nothrow;

        /++
         + Returns:
         +  The position of this object.
         + ++/
        @property @safe @nogc
        const(vec2) position() const nothrow;
    }
}

/++
 + An abstraction built on top of a 4x4 `Matrix` to make it easy to 
 + create a transformation matrix, such as the ones used for Model, View, and Projection transforms.
 +
 + Notes:
 +  Please make sure to look at `Transform.markDirty`, as it can save you from 'strange' bugs.
 + ++/
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
        /// 
        this(mat4 matrix)
        {
            this._matrix = matrix;
        }

        /++
         + Transforms the $(B positions) of each `Vertex` in the given array, in place.
         +
         + Notes:
         +  This function calls `Transform.matrix`, so the matrix will be updated
         +  if it's dirty.
         +
         + Params:
         +  verts = The verticies to transform.
         +
         + Returns:
         +  `verts`
         + ++/
        @safe @nogc
        Vertex[] transformVerts(return Vertex[] verts) nothrow
        {
            auto matrix = this.matrix;
            foreach(ref vert; verts)
                vert.position = vec2(matrix * vec4(vert.position, 0, 1.0));

            return verts;
        }
        
        /++
         + Notes:
         +  Can basically imagine this as the position.
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
         + Use this to tell the transform to update it's matrix.
         +
         + Any setter functions will do this automatically, but functions such as `translation`[get]
         + can be used to modify the transform without the dirty flag being set.
         + ++/
        pragma(inline, true)
        @safe @nogc
        void markDirty() nothrow pure
        {
            this._dirty = true;
        }

        /// Returns: Whether the matrix is dirty, and needs to be updated.
        pragma(inline, true)
        @property @safe @nogc
        bool isDirty() nothrow const pure
        {
            return this._dirty;
        }
        
        /++
         + Notes:
         +  If the matrix has been marked as being dirty (see `Transform.markDirty`) then the
         +  underlying matrix is recreated using the transform's current data. If the matrix isn't
         +  marked as dirty, then it will not be recreated and is simply returned as-is.
         +
         + Returns:
         +  A matrix containing all of the transformations specified by this struct.
         + ++/
        @property @safe @nogc
        mat4 matrix() nothrow
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
