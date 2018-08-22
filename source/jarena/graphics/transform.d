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

        /++
         + Sets the rotation of the transformable object.
         +
         + Params:
         +  angle = The rotation to set the object at.
         + ++/
        @property @safe @nogc
        void rotation(AngleDegrees angle) nothrow;

        /// ditto
        @property @safe @nogc
        final void rotationF(float angle) nothrow
        {
            this.rotation = AngleDegrees(angle);
        }

        /++
         + Sets the scale of the transformable object (default (1,1)).
         +
         + Params:
         +  amount = The amount to scale it by.
         + ++/
        @property @safe @nogc
        void scale(vec2 amount) nothrow;

        /++
         + Returns:
         +  The amount to scale it by.
         + ++/
        @property @safe @nogc
        const(vec2) scale() nothrow const;

        /++
         + Returns:
         +  The origin of this object.
         + ++/
        @property @safe @nogc
        const(vec2) origin() nothrow const;

        /++
         + Sets the origin of the transformable object.
         +
         + Params:
         +  point = The point to set the object's origin to.
         + ++/
        @property @safe @nogc
        void origin(vec2 point) nothrow;
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
        mat4         _matrix;
        vec2         _translation = vec2(0);
        vec2         _origin = vec2(0);
        vec2         _scale = vec2(1);
        AngleDegrees _rotation = AngleDegrees(0.0f);

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
        pragma(inline, true)
        @safe @nogc
        ref inout(vec2) translation() nothrow pure inout
        {
            return this._translation;
        }

        /++
         + Notes:
         +  Rotations are applied around the `Transform.origin`
         +
         + Returns:
         +  The rotation of this transformation.
         + ++/
        pragma(inline, true)
        @safe @nogc
        ref inout(AngleDegrees) rotation() nothrow pure inout
        {
            return this._rotation;
        }

        /++
         + Returns:
         +  The origin of this transformation.
         + ++/
        pragma(inline, true)
        @safe @nogc
        ref inout(vec2) origin() nothrow pure inout
        {
            return this._origin;
        }

        /++
         + Returns:
         +  The scale of this transformation.
         + ++/
        pragma(inline, true)
        @safe @nogc
        ref inout(vec2) scale() nothrow pure inout
        {
            return this._scale;
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
                this._matrix.translate(-this.origin.x, -this.origin.y, 0);
                this._matrix.scale(this._scale.x, this._scale.y, 1);
                this._matrix.rotateZ(this._rotation.angle);
                this._matrix.translate(this.origin.x, this.origin.y, 0);
                this._matrix.translate(this._translation.x, this._translation.y, 0);

                this._dirty = false;
            }
            
            return this._matrix;
        }
    }
}
