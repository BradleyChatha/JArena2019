module jarena.core.util;

private
{
    import jarena.core.maths;
    import derelict.sfml2.system, derelict.sfml2.graphics;
}

private enum isSFMLVector(T) = (is(T == sfVector2f) || is(T == sfVector2i) || is(T == sfVector2u));
private enum isDLSLVector(T) = isVector!T;

/// Implementation of the `to` function for - DLSL Vector -> SFML Vector
sfVect toSF(sfVect, dlslVect)(dlslVect vect)
if(isSFMLVector!sfVect && isDLSLVector!dlslVect)
{
    static assert(dlslVect.dimension == 2, "Since the SFML vectors we're using are all 2D, we go off the assumption that the DLSL one is also 2D");
    return sfVect(vect.x, vect.y);
}
///
unittest
{
    assert(ivec2(20, 40).toSF!sfVector2i == sfVector2i(20, 40));
}

/// Implementation of the `to` function for - SFML Vector -> DLSL Vector
dlslVect to(dlslVect, sfVect)(sfVect vect)
if(isSFMLVector!sfVect && isDLSLVector!dlslVect)
{
    static assert(dlslVect.dimension == 2, "Since the SFML vectors we're using are all 2D, we go off the assumption that the DLSL one is also 2D");
    return dlslVect(vect.x, vect.y);
}
///
unittest
{
    assert(sfVector2i(20, 40).to!ivec2 == ivec2(20, 40));
}

/// Implementation of the `to` function for - uvec4b -> sfColor
sfColor toSF(T : sfColor)(uvec4b vect)
{
    return sfColor(vect.r, vect.g, vect.b, vect.a);
}

/// Implementation of the `to` function for - RectangleI -> sfIntRect
sfIntRect toSF(T : sfIntRect)(RectangleI intRect)
{
    return sfIntRect(intRect.position.x, intRect.position.y, intRect.size.x, intRect.size.y);
}

/++
 + To get around limitations with how DLSL's `Vector` is implemented (or rather, how D works), this function is provided
 + to easily create a `uvec4b`, which is really only used for colours.
 + ++/
uvec4b colour(ubyte r, ubyte g, ubyte b, ubyte a)
{
    return uvec4b(r, g, b, a);
}