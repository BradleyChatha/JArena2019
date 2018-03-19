/++
 + Adam D Ruppe's colour.d
 +
 + Changes:
 +  Removed `Point`, `Size`, and `Rectangle`
 +
 +  Renamed `Color` to `Colour`
 + ++/
module arsd.colour;

@safe:

// importing phobos explodes the size of this code 10x, so not doing it.

private {
	real toInternal(T)(string s) {
		real accumulator = 0.0;
		size_t i = s.length;
		foreach(idx, c; s) {
			if(c >= '0' && c <= '9') {
				accumulator *= 10;
				accumulator += c - '0';
			} else if(c == '.') {
				i = idx + 1;
				break;
			} else
				throw new Exception("bad char to make real from " ~ s);
		}

		real accumulator2 = 0.0;
		real count = 1;
		foreach(c; s[i .. $]) {
			if(c >= '0' && c <= '9') {
				accumulator2 *= 10;
				accumulator2 += c - '0';
				count *= 10;
			} else
				throw new Exception("bad char to make real from " ~ s);
		}

		return accumulator + accumulator2 / count;
	}

	@trusted
	string toInternal(T)(int a) {
		if(a == 0)
			return "0";
		char[] ret;
		while(a) {
			ret ~= (a % 10) + '0';
			a /= 10;
		}
		for(int i = 0; i < ret.length / 2; i++) {
			char c = ret[i];
			ret[i] = ret[$ - i - 1];
			ret[$ - i - 1] = c;
		}
		return cast(string) ret;
	}
	string toInternal(T)(real a) {
		// a simplifying assumption here is the fact that we only use this in one place: toInternal!string(cast(real) a / 255)
		// thus we know this will always be between 0.0 and 1.0, inclusive.
		if(a <= 0.0)
			return "0.0";
		if(a >= 1.0)
			return "1.0";
		string ret = "0.";
		// I wonder if I can handle round off error any better. Phobos does, but that isn't worth 100 KB of code.
		int amt = cast(int)(a * 1000);
		return ret ~ toInternal!string(amt);
	}

	nothrow @safe @nogc pure
	real absInternal(real a) { return a < 0 ? -a : a; }
	nothrow @safe @nogc pure
	real minInternal(real a, real b, real c) {
		auto m = a;
		if(b < m) m = b;
		if(c < m) m = c;
		return m;
	}
	nothrow @safe @nogc pure
	real maxInternal(real a, real b, real c) {
		auto m = a;
		if(b > m) m = b;
		if(c > m) m = c;
		return m;
	}
	nothrow @safe @nogc pure
	bool startsWithInternal(string a, string b) {
		return (a.length >= b.length && a[0 .. b.length] == b);
	}
	string[] splitInternal(string a, char c) {
		string[] ret;
		size_t previous = 0;
		foreach(i, char ch; a) {
			if(ch == c) {
				ret ~= a[previous .. i];
				previous = i + 1;
			}
		}
		if(previous != a.length)
			ret ~= a[previous .. $];
		return ret;
	}
	nothrow @safe @nogc pure
	string stripInternal(string s) {
		foreach(i, char c; s)
			if(c != ' ' && c != '\t' && c != '\n') {
				s = s[i .. $];
				break;
			}
		for(int a = cast(int)(s.length - 1); a > 0; a--) {
			char c = s[a];
			if(c != ' ' && c != '\t' && c != '\n') {
				s = s[0 .. a + 1];
				break;
			}
		}

		return s;
	}
}

// done with mini-phobos

/// Represents an RGBA Colour
struct Colour {

@safe:
	/++
		The Colour components are available as a static array, individual bytes, and a uint inside this union.

		Since it is anonymous, you can use the inner members' names directly.
	+/
	union {
		ubyte[4] components; /// [r, g, b, a]

		/// Holder for rgba individual components.
		struct {
			ubyte r; /// red
			ubyte g; /// green
			ubyte b; /// blue
			ubyte a; /// alpha. 255 == opaque
		}

		uint asUint; /// The components as a single 32 bit value (beware of endian issues!)
	}

	/++
		Like the constructor, but this makes sure they are in range before casting. If they are out of range, it saturates: anything less than zero becomes zero and anything greater than 255 becomes 255.
	+/
	nothrow pure
	static Colour fromIntegers(int red, int green, int blue, int alpha = 255) {
		return Colour(clampToByte(red), clampToByte(green), clampToByte(blue), clampToByte(alpha));
	}

	/// Construct a Colour with the given values. They should be in range 0 <= x <= 255, where 255 is maximum intensity and 0 is minimum intensity.
	nothrow pure @nogc
	this(int red, int green, int blue, int alpha = 255) {
		this.r = cast(ubyte) red;
		this.g = cast(ubyte) green;
		this.b = cast(ubyte) blue;
		this.a = cast(ubyte) alpha;
	}

	/// Static convenience functions for common Colour names
	nothrow pure @nogc
	static Colour transparent() { return Colour(0, 0, 0, 0); }
	/// Ditto
	nothrow pure @nogc
	static Colour white() { return Colour(255, 255, 255); }
	/// Ditto
	nothrow pure @nogc
	static Colour gray() { return Colour(128, 128, 128); }
	/// Ditto
	nothrow pure @nogc
	static Colour black() { return Colour(0, 0, 0); }
	/// Ditto
	nothrow pure @nogc
	static Colour red() { return Colour(255, 0, 0); }
	/// Ditto
	nothrow pure @nogc
	static Colour green() { return Colour(0, 255, 0); }
	/// Ditto
	nothrow pure @nogc
	static Colour blue() { return Colour(0, 0, 255); }
	/// Ditto
	nothrow pure @nogc
	static Colour yellow() { return Colour(255, 255, 0); }
	/// Ditto
	nothrow pure @nogc
	static Colour teal() { return Colour(0, 255, 255); }
	/// Ditto
	nothrow pure @nogc
	static Colour purple() { return Colour(255, 0, 255); }
	/// Ditto
	nothrow pure @nogc
	static Colour brown() { return Colour(128, 64, 0); }

	/*
	ubyte[4] toRgbaArray() {
		return [r,g,b,a];
	}
	*/

	/// Return black-and-white Colour
	Colour toBW() () {
		int intens = clampToByte(cast(int)(0.2126*r+0.7152*g+0.0722*b));
		return Colour(intens, intens, intens, a);
	}

	/// Makes a string that matches CSS syntax for websites
	string toCssString() const {
		if(a == 255)
			return "#" ~ toHexInternal(r) ~ toHexInternal(g) ~ toHexInternal(b);
		else {
			return "rgba("~toInternal!string(r)~", "~toInternal!string(g)~", "~toInternal!string(b)~", "~toInternal!string(cast(real)a / 255.0)~")";
		}
	}

	/// Makes a hex string RRGGBBAA (aa only present if it is not 255)
	string toString() const {
		if(a == 255)
			return toCssString()[1 .. $];
		else
			return toRgbaHexString();
	}

	/// returns RRGGBBAA, even if a== 255
	string toRgbaHexString() const {
		return toHexInternal(r) ~ toHexInternal(g) ~ toHexInternal(b) ~ toHexInternal(a);
	}

	/// Gets a Colour by name, iff the name is one of the static members listed above
	static Colour fromNameString(string s) {
		Colour c;
		foreach(member; __traits(allMembers, Colour)) {
			static if(__traits(compiles, c = __traits(getMember, Colour, member))) {
				if(s == member)
					return __traits(getMember, Colour, member);
			}
		}
		throw new Exception("Unknown Colour " ~ s);
	}

	/// Reads a CSS style string to get the Colour. Understands #rrggbb, rgba(), hsl(), and rrggbbaa
	static Colour fromString(string s) {
		s = s.stripInternal();

		Colour c;
		c.a = 255;

		// trying named Colours via the static no-arg methods here
		foreach(member; __traits(allMembers, Colour)) {
			static if(__traits(compiles, c = __traits(getMember, Colour, member))) {
				if(s == member)
					return __traits(getMember, Colour, member);
			}
		}

		// try various notations borrowed from CSS (though a little extended)

		// hsl(h,s,l,a) where h is degrees and s,l,a are 0 >= x <= 1.0
		if(s.startsWithInternal("hsl(") || s.startsWithInternal("hsla(")) {
			assert(s[$-1] == ')');
			s = s[s.startsWithInternal("hsl(") ? 4 : 5  .. $ - 1]; // the closing paren

			real[3] hsl;
			ubyte a = 255;

			auto parts = s.splitInternal(',');
			foreach(i, part; parts) {
				if(i < 3)
					hsl[i] = toInternal!real(part.stripInternal);
				else
					a = clampToByte(cast(int) (toInternal!real(part.stripInternal) * 255));
			}

			c = .fromHsl(hsl);
			c.a = a;

			return c;
		}

		// rgb(r,g,b,a) where r,g,b are 0-255 and a is 0-1.0
		if(s.startsWithInternal("rgb(") || s.startsWithInternal("rgba(")) {
			assert(s[$-1] == ')');
			s = s[s.startsWithInternal("rgb(") ? 4 : 5  .. $ - 1]; // the closing paren

			auto parts = s.splitInternal(',');
			foreach(i, part; parts) {
				// lol the loop-switch pattern
				auto v = toInternal!real(part.stripInternal);
				switch(i) {
					case 0: // red
						c.r = clampToByte(cast(int) v);
					break;
					case 1:
						c.g = clampToByte(cast(int) v);
					break;
					case 2:
						c.b = clampToByte(cast(int) v);
					break;
					case 3:
						c.a = clampToByte(cast(int) (v * 255));
					break;
					default: // ignore
				}
			}

			return c;
		}




		// otherwise let's try it as a hex string, really loosely

		if(s.length && s[0] == '#')
			s = s[1 .. $];

		// not a built in... do it as a hex string
		if(s.length >= 2) {
			c.r = fromHexInternal(s[0 .. 2]);
			s = s[2 .. $];
		}
		if(s.length >= 2) {
			c.g = fromHexInternal(s[0 .. 2]);
			s = s[2 .. $];
		}
		if(s.length >= 2) {
			c.b = fromHexInternal(s[0 .. 2]);
			s = s[2 .. $];
		}
		if(s.length >= 2) {
			c.a = fromHexInternal(s[0 .. 2]);
			s = s[2 .. $];
		}

		return c;
	}

	/// from hsl
	static Colour fromHsl(real h, real s, real l) {
		return .fromHsl(h, s, l);
	}

	// this is actually branch-less for ints on x86, and even for longs on x86_64
	static ubyte clampToByte(T) (T n) pure nothrow @safe @nogc if (__traits(isIntegral, T)) {
		static if (__VERSION__ > 2067) pragma(inline, true);
		static if (T.sizeof == 2 || T.sizeof == 4) {
			static if (__traits(isUnsigned, T)) {
				return cast(ubyte)(n&0xff|(255-((-cast(int)(n < 256))>>24)));
			} else {
				n &= -cast(int)(n >= 0);
				return cast(ubyte)(n|((255-cast(int)n)>>31));
			}
		} else static if (T.sizeof == 1) {
			static assert(__traits(isUnsigned, T), "clampToByte: signed byte? no, really?");
			return cast(ubyte)n;
		} else static if (T.sizeof == 8) {
			static if (__traits(isUnsigned, T)) {
				return cast(ubyte)(n&0xff|(255-((-cast(long)(n < 256))>>56)));
			} else {
				n &= -cast(long)(n >= 0);
				return cast(ubyte)(n|((255-cast(long)n)>>63));
			}
		} else {
			static assert(false, "clampToByte: integer too big");
		}
	}

	/** this mixin can be used to alphablend two `uint` Colours;
	 * `colu32name` is variable that holds Colour to blend,
	 * `destu32name` is variable that holds "current" Colour (from surface, for example).
	 * alpha value of `destu32name` doesn't matter.
	 * alpha value of `colu32name` means: 255 for replace Colour, 0 for keep `destu32name`.
	 *
	 * WARNING! This function does blending in RGB space, and RGB space is not linear!
	 */
	public enum ColourBlendMixinStr(string colu32name, string destu32name) = "{
		immutable uint a_tmp_ = (256-(255-(("~colu32name~")>>24)))&(-(1-(((255-(("~colu32name~")>>24))+1)>>8))); // to not loose bits, but 255 should become 0
		immutable uint dc_tmp_ = ("~destu32name~")&0xffffff;
		immutable uint srb_tmp_ = (("~colu32name~")&0xff00ff);
		immutable uint sg_tmp_ = (("~colu32name~")&0x00ff00);
		immutable uint drb_tmp_ = (dc_tmp_&0xff00ff);
		immutable uint dg_tmp_ = (dc_tmp_&0x00ff00);
		immutable uint orb_tmp_ = (drb_tmp_+(((srb_tmp_-drb_tmp_)*a_tmp_+0x800080)>>8))&0xff00ff;
		immutable uint og_tmp_ = (dg_tmp_+(((sg_tmp_-dg_tmp_)*a_tmp_+0x008000)>>8))&0x00ff00;
		("~destu32name~") = (orb_tmp_|og_tmp_)|0xff000000; /*&0xffffff;*/
	}";


	/// Perform alpha-blending of `fore` to this Colour, return new Colour.
	/// WARNING! This function does blending in RGB space, and RGB space is not linear!
	Colour alphaBlend (Colour fore) const pure nothrow @trusted @nogc {
		static if (__VERSION__ > 2067) pragma(inline, true);
		Colour res;
		res.asUint = asUint;
		mixin(ColourBlendMixinStr!("fore.asUint", "res.asUint"));
		return res;
	}
}

nothrow @safe
private string toHexInternal(ubyte b) {
	string s;
	if(b < 16)
		s ~= '0';
	else {
		ubyte t = (b & 0xf0) >> 4;
		if(t >= 10)
			s ~= 'A' + t - 10;
		else
			s ~= '0' + t;
		b &= 0x0f;
	}
	if(b >= 10)
		s ~= 'A' + b - 10;
	else
		s ~= '0' + b;

	return s;
}

nothrow @safe @nogc pure
private ubyte fromHexInternal(string s) {
	int result = 0;

	int exp = 1;
	//foreach(c; retro(s)) { // FIXME: retro doesn't work right in dtojs
	foreach_reverse(c; s) {
		if(c >= 'A' && c <= 'F')
			result += exp * (c - 'A' + 10);
		else if(c >= 'a' && c <= 'f')
			result += exp * (c - 'a' + 10);
		else if(c >= '0' && c <= '9')
			result += exp * (c - '0');
		else
			// throw new Exception("invalid hex character: " ~ cast(char) c);
			return 0;

		exp *= 16;
	}

	return cast(ubyte) result;
}

/// Converts hsl to rgb
Colour fromHsl(real[3] hsl) {
	return fromHsl(hsl[0], hsl[1], hsl[2]);
}

/// Converts hsl to rgb
Colour fromHsl(real h, real s, real l, real a = 255) {
	h = h % 360;

	real C = (1 - absInternal(2 * l - 1)) * s;

	real hPrime = h / 60;

	real X = C * (1 - absInternal(hPrime % 2 - 1));

	real r, g, b;

	if(h is real.nan)
		r = g = b = 0;
	else if (hPrime >= 0 && hPrime < 1) {
		r = C;
		g = X;
		b = 0;
	} else if (hPrime >= 1 && hPrime < 2) {
		r = X;
		g = C;
		b = 0;
	} else if (hPrime >= 2 && hPrime < 3) {
		r = 0;
		g = C;
		b = X;
	} else if (hPrime >= 3 && hPrime < 4) {
		r = 0;
		g = X;
		b = C;
	} else if (hPrime >= 4 && hPrime < 5) {
		r = X;
		g = 0;
		b = C;
	} else if (hPrime >= 5 && hPrime < 6) {
		r = C;
		g = 0;
		b = X;
	}

	real m = l - C / 2;

	r += m;
	g += m;
	b += m;

	return Colour(
		cast(int)(r * 255),
		cast(int)(g * 255),
		cast(int)(b * 255),
		cast(int)(a));
}

/// Converts an RGB Colour into an HSL triplet. useWeightedLightness will try to get a better value for luminosity for the human eye, which is more sensitive to green than red and more to red than blue. If it is false, it just does average of the rgb.
real[3] toHsl(Colour c, bool useWeightedLightness = false) {
	real r1 = cast(real) c.r / 255;
	real g1 = cast(real) c.g / 255;
	real b1 = cast(real) c.b / 255;

	real maxColour = maxInternal(r1, g1, b1);
	real minColour = minInternal(r1, g1, b1);

	real L = (maxColour + minColour) / 2 ;
	if(useWeightedLightness) {
		// the Colours don't affect the eye equally
		// this is a little more accurate than plain HSL numbers
		L = 0.2126*r1 + 0.7152*g1 + 0.0722*b1;
	}
	real S = 0;
	real H = 0;
	if(maxColour != minColour) {
		if(L < 0.5) {
			S = (maxColour - minColour) / (maxColour + minColour);
		} else {
			S = (maxColour - minColour) / (2.0 - maxColour - minColour);
		}
		if(r1 == maxColour) {
			H = (g1-b1) / (maxColour - minColour);
		} else if(g1 == maxColour) {
			H = 2.0 + (b1 - r1) / (maxColour - minColour);
		} else {
			H = 4.0 + (r1 - g1) / (maxColour - minColour);
		}
	}

	H = H * 60;
	if(H < 0){
		H += 360;
	}

	return [H, S, L]; 
}

/// .
Colour lighten(Colour c, real percentage) {
	auto hsl = toHsl(c);
	hsl[2] *= (1 + percentage);
	if(hsl[2] > 1)
		hsl[2] = 1;
	return fromHsl(hsl);
}

/// .
Colour darken(Colour c, real percentage) {
	auto hsl = toHsl(c);
	hsl[2] *= (1 - percentage);
	return fromHsl(hsl);
}

/// for light Colours, call darken. for dark Colours, call lighten.
/// The goal: get toward center grey.
Colour moderate(Colour c, real percentage) {
	auto hsl = toHsl(c);
	if(hsl[2] > 0.5)
		hsl[2] *= (1 - percentage);
	else {
		if(hsl[2] <= 0.01) // if we are given black, moderating it means getting *something* out
			hsl[2] = percentage;
		else
			hsl[2] *= (1 + percentage);
	}
	if(hsl[2] > 1)
		hsl[2] = 1;
	return fromHsl(hsl);
}

/// the opposite of moderate. Make darks darker and lights lighter
Colour extremify(Colour c, real percentage) {
	auto hsl = toHsl(c, true);
	if(hsl[2] < 0.5)
		hsl[2] *= (1 - percentage);
	else
		hsl[2] *= (1 + percentage);
	if(hsl[2] > 1)
		hsl[2] = 1;
	return fromHsl(hsl);
}

/// Move around the lightness wheel, trying not to break on moderate things
Colour oppositeLightness(Colour c) {
	auto hsl = toHsl(c);

	auto original = hsl[2];

	if(original > 0.4 && original < 0.6)
		hsl[2] = 0.8 - original; // so it isn't quite the same
	else
		hsl[2] = 1 - original;

	return fromHsl(hsl);
}

/// Try to determine a text Colour - either white or black - based on the input
Colour makeTextColour(Colour c) {
	auto hsl = toHsl(c, true); // give green a bonus for contrast
	if(hsl[2] > 0.71)
		return Colour(0, 0, 0);
	else
		return Colour(255, 255, 255);
}

// These provide functional access to hsl manipulation; useful if you need a delegate

Colour setLightness(Colour c, real lightness) {
	auto hsl = toHsl(c);
	hsl[2] = lightness;
	return fromHsl(hsl);
}


///
Colour rotateHue(Colour c, real degrees) {
	auto hsl = toHsl(c);
	hsl[0] += degrees;
	return fromHsl(hsl);
}

///
Colour setHue(Colour c, real hue) {
	auto hsl = toHsl(c);
	hsl[0] = hue;
	return fromHsl(hsl);
}

///
Colour desaturate(Colour c, real percentage) {
	auto hsl = toHsl(c);
	hsl[1] *= (1 - percentage);
	return fromHsl(hsl);
}

///
Colour saturate(Colour c, real percentage) {
	auto hsl = toHsl(c);
	hsl[1] *= (1 + percentage);
	if(hsl[1] > 1)
		hsl[1] = 1;
	return fromHsl(hsl);
}

///
Colour setSaturation(Colour c, real saturation) {
	auto hsl = toHsl(c);
	hsl[1] = saturation;
	return fromHsl(hsl);
}


/*
void main(string[] args) {
	auto Colour1 = toHsl(Colour(255, 0, 0));
	auto Colour = fromHsl(Colour1[0] + 60, Colour1[1], Colour1[2]);

	writefln("#%02x%02x%02x", Colour.r, Colour.g, Colour.b);
}
*/

/* Colour algebra functions */

/* Alpha putpixel looks like this:

void putPixel(Image i, Colour c) {
	Colour b;
	b.r = i.data[(y * i.width + x) * bpp + 0];
	b.g = i.data[(y * i.width + x) * bpp + 1];
	b.b = i.data[(y * i.width + x) * bpp + 2];
	b.a = i.data[(y * i.width + x) * bpp + 3];

	float ca = cast(float) c.a / 255;

	i.data[(y * i.width + x) * bpp + 0] = alpha(c.r, ca, b.r);
	i.data[(y * i.width + x) * bpp + 1] = alpha(c.g, ca, b.g);
	i.data[(y * i.width + x) * bpp + 2] = alpha(c.b, ca, b.b);
	i.data[(y * i.width + x) * bpp + 3] = alpha(c.a, ca, b.a);
}

ubyte alpha(ubyte c1, float alpha, ubyte onto) {
	auto got = (1 - alpha) * onto + alpha * c1;

	if(got > 255)
		return 255;
	return cast(ubyte) got;
}

So, given the background Colour and the resultant Colour, what was
composited on to it?
*/

///
ubyte unalpha(ubyte ColourYouHave, float alpha, ubyte backgroundColour) {
	// resultingColour = (1-alpha) * backgroundColour + alpha * answer
	auto resultingColourf = cast(float) ColourYouHave;
	auto backgroundColourf = cast(float) backgroundColour;

	auto answer = (resultingColourf - backgroundColourf + alpha * backgroundColourf) / alpha;
	return Colour.clampToByte(cast(int) answer);
}

///
ubyte makeAlpha(ubyte ColourYouHave, ubyte backgroundColour/*, ubyte foreground = 0x00*/) {
	//auto foregroundf = cast(float) foreground;
	auto foregroundf = 0.00f;
	auto ColourYouHavef = cast(float) ColourYouHave;
	auto backgroundColourf = cast(float) backgroundColour;

	// ColourYouHave = backgroundColourf - alpha * backgroundColourf + alpha * foregroundf
	auto alphaf = 1 - ColourYouHave / backgroundColourf;
	alphaf *= 255;

	return Colour.clampToByte(cast(int) alphaf);
}


int fromHex(string s) {
	int result = 0;

	int exp = 1;
	// foreach(c; retro(s)) {
	foreach_reverse(c; s) {
		if(c >= 'A' && c <= 'F')
			result += exp * (c - 'A' + 10);
		else if(c >= 'a' && c <= 'f')
			result += exp * (c - 'a' + 10);
		else if(c >= '0' && c <= '9')
			result += exp * (c - '0');
		else
			throw new Exception("invalid hex character: " ~ cast(char) c);

		exp *= 16;
	}

	return result;
}

///
Colour ColourFromString(string s) {
	if(s.length == 0)
		return Colour(0,0,0,255);
	if(s[0] == '#')
		s = s[1..$];
	assert(s.length == 6 || s.length == 8);

	Colour c;

	c.r = cast(ubyte) fromHex(s[0..2]);
	c.g = cast(ubyte) fromHex(s[2..4]);
	c.b = cast(ubyte) fromHex(s[4..6]);
	if(s.length == 8)
		c.a = cast(ubyte) fromHex(s[6..8]);
	else
		c.a = 255;

	return c;
}

/*
import browser.window;
import std.conv;
void main() {
	import browser.document;
	foreach(ele; document.querySelectorAll("input")) {
		ele.addEventListener("change", {
			auto h = toInternal!real(document.querySelector("input[name=h]").value);
			auto s = toInternal!real(document.querySelector("input[name=s]").value);
			auto l = toInternal!real(document.querySelector("input[name=l]").value);

			Colour c = Colour.fromHsl(h, s, l);

			auto e = document.getElementById("example");
			e.style.backgroundColour = c.toCssString();

			// JSElement __js_this;
			// __js_this.style.backgroundColour = c.toCssString();
		}, false);
	}
}
*/



/**
	This provides two image classes and a bunch of functions that work on them.

	Why are they separate classes? I think the operations on the two of them
	are necessarily different. There's a whole bunch of operations that only
	really work on trueColour (blurs, gradients), and a few that only work
	on indexed images (palette swaps).

	Even putpixel is pretty different. On indexed, it is a palette entry's
	index number. On trueColour, it is the actual Colour.

	A greyscale image is the weird thing in the middle. It is trueColour, but
	fits in the same size as indexed. Still, I'd say it is a specialization
	of trueColour.

	There is a subset that works on both

*/

/// An image in memory
interface MemoryImage {
	//IndexedImage convertToIndexedImage() const;
	//TrueColourImage convertToTrueColour() const;

	/// gets it as a TrueColourImage. May return this or may do a conversion and return a new image
	TrueColourImage getAsTrueColourImage();

	/// Image width, in pixels
	int width() const;

	/// Image height, in pixels
	int height() const;

	/// Get image pixel. Slow, but returns valid RGBA Colour (completely transparent for off-image pixels).
	Colour getPixel(int x, int y) const;

  /// Set image pixel.
	void setPixel(int x, int y, in Colour clr);

	/// Returns a copy of the image
	MemoryImage clone() const;

	/// Load image from file. This will import arsd.image to do the actual work, and cost nothing if you don't use it.
	static MemoryImage fromImage(T : const(char)[]) (T filename) @trusted {
		static if (__traits(compiles, (){import arsd.image;})) {
			// yay, we have image loader here, try it!
			import arsd.image;
			return loadImageFromFile(filename);
		} else {
			static assert(0, "please provide 'arsd.image' to load images!");
		}
	}

	// ***This method is deliberately not publicly documented.***
	// What it does is unconditionally frees internal image storage, without any sanity checks.
	// If you will do this, make sure that you have no references to image data left (like
	// slices of [data] array, for example). Those references will become invalid, and WILL
	// lead to Undefined Behavior.
	// tl;dr: IF YOU HAVE *ANY* QUESTIONS REGARDING THIS COMMENT, DON'T USE THIS!
	// Note to implementors: it is safe to simply do nothing in this method.
	// Also, it should be safe to call this method twice or more.
	void clearInternal () nothrow @system;// @nogc; // nogc is commented right now just because GC.free is only @nogc in newest dmd and i want to stay compatible a few versions back too. it can be added later

	/// Convenient alias for `fromImage`
	alias fromImageFile = fromImage;
}

/// An image that consists of indexes into a Colour palette. Use [getAsTrueColourImage]() if you don't care about palettes
class IndexedImage : MemoryImage {
	bool hasAlpha;

	/// .
	Colour[] palette;
	/// the data as indexes into the palette. Stored left to right, top to bottom, no padding.
	ubyte[] data;

	override void clearInternal () nothrow @system {// @nogc {
		import core.memory : GC;
		// it is safe to call [GC.free] with `null` pointer.
		GC.free(palette.ptr); palette = null;
		GC.free(data.ptr); data = null;
		_width = _height = 0;
	}

	/// .
	override int width() const {
		return _width;
	}

	/// .
	override int height() const {
		return _height;
	}

	/// .
	override IndexedImage clone() const {
		auto n = new IndexedImage(width, height);
		n.data[] = this.data[]; // the data member is already there, so array copy
		n.palette = this.palette.dup; // and here we need to allocate too, so dup
		n.hasAlpha = this.hasAlpha;
		return n;
	}

	override Colour getPixel(int x, int y) const @trusted {
		if (x >= 0 && y >= 0 && x < _width && y < _height) {
			uint pos = y*_width+x;
			if (pos >= data.length) return Colour(0, 0, 0, 0);
			ubyte b = data.ptr[pos];
			if (b >= palette.length) return Colour(0, 0, 0, 0);
			return palette.ptr[b];
		} else {
			return Colour(0, 0, 0, 0);
		}
	}

	override void setPixel(int x, int y, in Colour clr) @trusted {
		if (x >= 0 && y >= 0 && x < _width && y < _height) {
			uint pos = y*_width+x;
			if (pos >= data.length) return;
			ubyte pidx = findNearestColour(palette, clr);
			if (palette.length < 255 &&
				 (palette.ptr[pidx].r != clr.r || palette.ptr[pidx].g != clr.g || palette.ptr[pidx].b != clr.b || palette.ptr[pidx].a != clr.a)) {
				// add new Colour
				pidx = addColour(clr);
			}
			data.ptr[pos] = pidx;
		}
	}

	private int _width;
	private int _height;

	/// .
	this(int w, int h) {
		_width = w;
		_height = h;
		data = new ubyte[w*h];
	}

	/*
	void resize(int w, int h, bool scale) {

	}
	*/

	/// returns a new image
	override TrueColourImage getAsTrueColourImage() {
		return convertToTrueColour();
	}

	/// Creates a new TrueColourImage based on this data
	TrueColourImage convertToTrueColour() const {
		auto tci = new TrueColourImage(width, height);
		foreach(i, b; data) {
			/*
			if(b >= palette.length) {
				string fuckyou;
				fuckyou ~= b + '0';
				fuckyou ~= " ";
				fuckyou ~= palette.length + '0';
				assert(0, fuckyou);
			}
			*/
			tci.imageData.Colours[i] = palette[b];
		}
		return tci;
	}

	/// Gets an exact match, if possible, adds if not. See also: the findNearestColour free function.
	ubyte getOrAddColour(Colour c) {
		foreach(i, co; palette) {
			if(c == co)
				return cast(ubyte) i;
		}

		return addColour(c);
	}

	/// Number of Colours currently in the palette (note: palette entries are not necessarily used in the image data)
	int numColours() const {
		return cast(int) palette.length;
	}

	/// Adds an entry to the palette, returning its inded
	ubyte addColour(Colour c) {
		assert(palette.length < 256);
		if(c.a != 255)
			hasAlpha = true;
		palette ~= c;

		return cast(ubyte) (palette.length - 1);
	}
}

/// An RGBA array of image data. Use the free function quantize() to convert to an IndexedImage
class TrueColourImage : MemoryImage {
//	bool hasAlpha;
//	bool isGreyscale;

	//ubyte[] data; // stored as rgba quads, upper left to right to bottom
	/// .
	struct Data {
		ubyte[] bytes; /// the data as rgba bytes. Stored left to right, top to bottom, no padding.
		// the union is no good because the length of the struct is wrong!

		/// the same data as Colour structs
		@trusted // the cast here is typically unsafe, but it is ok
		// here because I guarantee the layout, note the static assert below
		@property inout(Colour)[] Colours() inout {
			return cast(inout(Colour)[]) bytes;
		}

		static assert(Colour.sizeof == 4);
	}

	/// .
	Data imageData;
	alias imageData.bytes data;

	int _width;
	int _height;

	override void clearInternal () nothrow @system {// @nogc {
		import core.memory : GC;
		// it is safe to call [GC.free] with `null` pointer.
		GC.free(imageData.bytes.ptr); imageData.bytes = null;
		_width = _height = 0;
	}

	/// .
	override TrueColourImage clone() const {
		auto n = new TrueColourImage(width, height);
		n.imageData.bytes[] = this.imageData.bytes[]; // copy into existing array ctor allocated
		return n;
	}

	/// .
	override int width() const { return _width; }
	///.
	override int height() const { return _height; }

	override Colour getPixel(int x, int y) const @trusted {
		if (x >= 0 && y >= 0 && x < _width && y < _height) {
			uint pos = y*_width+x;
			return imageData.Colours.ptr[pos];
		} else {
			return Colour(0, 0, 0, 0);
		}
	}

	override void setPixel(int x, int y, in Colour clr) @trusted {
		if (x >= 0 && y >= 0 && x < _width && y < _height) {
			uint pos = y*_width+x;
			if (pos < imageData.bytes.length/4) imageData.Colours.ptr[pos] = clr;
		}
	}

	/// .
	this(int w, int h) {
		_width = w;
		_height = h;
		imageData.bytes = new ubyte[w*h*4];
	}

	/// Creates with existing data. The data pointer is stored here.
	this(int w, int h, ubyte[] data) {
		_width = w;
		_height = h;
		assert(data.length == w * h * 4);
		imageData.bytes = data;
	}

	/// Returns this
	override TrueColourImage getAsTrueColourImage() {
		return this;
	}
}

/// Converts true Colour to an indexed image. It uses palette as the starting point, adding entries
/// until maxColours as needed. If palette is null, it creates a whole new palette.
///
/// After quantizing the image, it applies a dithering algorithm.
///
/// This is not written for speed.
IndexedImage quantize(in TrueColourImage img, Colour[] palette = null, in int maxColours = 256)
	// this is just because IndexedImage assumes ubyte palette values
	in { assert(maxColours <= 256); }
body {
	int[Colour] uses;
	foreach(pixel; img.imageData.Colours) {
		if(auto i = pixel in uses) {
			(*i)++;
		} else {
			uses[pixel] = 1;
		}
	}

	struct ColourUse {
		Colour c;
		int uses;
		//string toString() { import std.conv; return c.toCssString() ~ " x " ~ to!string(uses); }
		int opCmp(ref const ColourUse co) const {
			return co.uses - uses;
		}
	}

	ColourUse[] sorted;

	foreach(Colour, count; uses)
		sorted ~= ColourUse(Colour, count);

	uses = null;
	//version(no_phobos)
		//sorted = sorted.sort;
	//else {
		import std.algorithm : sort;
		sort(sorted);
	//}

	ubyte[Colour] paletteAssignments;
	foreach(idx, entry; palette)
		paletteAssignments[entry] = cast(ubyte) idx;

	// For the Colour assignments from the image, I do multiple passes, decreasing the acceptable
	// distance each time until we're full.

	// This is probably really slow.... but meh it gives pretty good results.

	auto ddiff = 32;
	outer: for(int d1 = 128; d1 >= 0; d1 -= ddiff) {
	auto minDist = d1*d1;
	if(d1 <= 64)
		ddiff = 16;
	if(d1 <= 32)
		ddiff = 8;
	foreach(possibility; sorted) {
		if(palette.length == maxColours)
			break;
		if(palette.length) {
			auto co = palette[findNearestColour(palette, possibility.c)];
			auto pixel = possibility.c;

			auto dr = cast(int) co.r - pixel.r;
			auto dg = cast(int) co.g - pixel.g;
			auto db = cast(int) co.b - pixel.b;

			auto dist = dr*dr + dg*dg + db*db;
			// not good enough variety to justify an allocation yet
			if(dist < minDist)
				continue;
		}
		paletteAssignments[possibility.c] = cast(ubyte) palette.length;
		palette ~= possibility.c;
	}
	}

	// Final pass: just fill in any remaining space with the leftover common Colours
	while(palette.length < maxColours && sorted.length) {
		if(sorted[0].c !in paletteAssignments) {
			paletteAssignments[sorted[0].c] = cast(ubyte) palette.length;
			palette ~= sorted[0].c;
		}
		sorted = sorted[1 .. $];
	}


	bool wasPerfect = true;
	auto newImage = new IndexedImage(img.width, img.height);
	newImage.palette = palette;
	foreach(idx, pixel; img.imageData.Colours) {
		if(auto p = pixel in paletteAssignments)
			newImage.data[idx] = *p;
		else {
			// gotta find the closest one...
			newImage.data[idx] = findNearestColour(palette, pixel);
			wasPerfect = false;
		}
	}

	if(!wasPerfect)
		floydSteinbergDither(newImage, img);

	return newImage;
}

/// Finds the best match for pixel in palette (currently by checking for minimum euclidean distance in rgb Colourspace)
ubyte findNearestColour(in Colour[] palette, in Colour pixel) {
	int best = 0;
	int bestDistance = int.max;
	foreach(pe, co; palette) {
		auto dr = cast(int) co.r - pixel.r;
		auto dg = cast(int) co.g - pixel.g;
		auto db = cast(int) co.b - pixel.b;
		int dist = dr*dr + dg*dg + db*db;

		if(dist < bestDistance) {
			best = cast(int) pe;
			bestDistance = dist;
		}
	}

	return cast(ubyte) best;
}

/+

// Quantizing and dithering test program

void main( ){
/*
	auto img = new TrueColourImage(256, 32);
	foreach(y; 0 .. img.height) {
		foreach(x; 0 .. img.width) {
			img.imageData.Colours[x + y * img.width] = Colour(x, y * (255 / img.height), 0);
		}
	}
*/

TrueColourImage img;

{

import arsd.png;

struct P {
	ubyte[] range;
	void put(ubyte[] a) { range ~= a; }
}

P range;
import std.algorithm;

import std.stdio;
writePngLazy(range, pngFromBytes(File("/home/me/nyesha.png").byChunk(4096)).byRgbaScanline.map!((line) {
	foreach(ref pixel; line.pixels) {
	continue;
		auto sum = cast(int) pixel.r + pixel.g + pixel.b;
		ubyte a = cast(ubyte)(sum / 3);
		pixel.r = a;
		pixel.g = a;
		pixel.b = a;
	}
	return line;
}));

img = imageFromPng(readPng(range.range)).getAsTrueColourImage;


}



	auto qimg = quantize(img, null, 2);

	import arsd.simpledisplay;
	auto win = new SimpleWindow(img.width, img.height * 3);
	auto painter = win.draw();
	painter.drawImage(Point(0, 0), Image.fromMemoryImage(img));
	painter.drawImage(Point(0, img.height), Image.fromMemoryImage(qimg));
	floydSteinbergDither(qimg, img);
	painter.drawImage(Point(0, img.height * 2), Image.fromMemoryImage(qimg));
	win.eventLoop(0);
}
+/

/+
/// If the background is transparent, it simply erases the alpha channel.
void removeTransparency(IndexedImage img, Colour background)
+/

/// Perform alpha-blending of `fore` to this Colour, return new Colour.
/// WARNING! This function does blending in RGB space, and RGB space is not linear!
Colour alphaBlend(Colour foreground, Colour background) pure nothrow @safe @nogc {
	static if (__VERSION__ > 2067) pragma(inline, true);
	return background.alphaBlend(foreground);
}

/*
/// Reduces the number of Colours in a palette.
void reducePaletteSize(IndexedImage img, int maxColours = 16) {

}
*/

// I think I did this wrong... but the results aren't too bad so the bug can't be awful.
/// Dithers img in place to look more like original.
void floydSteinbergDither(IndexedImage img, in TrueColourImage original) {
	assert(img.width == original.width);
	assert(img.height == original.height);

	auto buffer = new Colour[](original.imageData.Colours.length);

	int x, y;

	foreach(idx, c; original.imageData.Colours) {
		auto n = img.palette[img.data[idx]];
		int errorR = cast(int) c.r - n.r;
		int errorG = cast(int) c.g - n.g;
		int errorB = cast(int) c.b - n.b;

		void doit(int idxOffset, int multiplier) {
		//	if(idx + idxOffset < buffer.length)
				buffer[idx + idxOffset] = Colour.fromIntegers(
					c.r + multiplier * errorR / 16,
					c.g + multiplier * errorG / 16,
					c.b + multiplier * errorB / 16,
					c.a
				);
		}

		if((x+1) != original.width)
			doit(1, 7);
		if((y+1) != original.height) {
			if(x != 0)
				doit(-1 + img.width, 3);
			doit(img.width, 5);
			if(x+1 != original.width)
				doit(1 + img.width, 1);
		}

		img.data[idx] = findNearestColour(img.palette, buffer[idx]);

		x++;
		if(x == original.width) {
			x = 0;
			y++;
		}
	}
}
