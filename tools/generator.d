version(FileGenerator)
{
    import std.conv : to;
    import codebuilder;
    
    const COLOUR_DATA_FILE = "colours.txt";
    const COLOUR_D_PATH = "../source/jarena/graphics/colours.d";

    void main()
    {
        import std.file : write;

        write(COLOUR_D_PATH, genColourModule());
    }
    
    public string genColourModule()
    {
        auto code = new CodeBuilder();
        code.putf("// Generated on %s at %s with jarena:generator", __DATE__, __TIME__);
        code.put("module jarena.graphics.colours;");
        code.put("public import arsd.colour;");

        code.put("abstract class Colours");
        code.putScope((_)
        {
            code.put("public static @nogc @safe nothrow pure const:");
            code.genColours();
        });

        return code.data.to!string;
    }
    
    private immutable colourData = import(COLOUR_DATA_FILE);
    private void genColours(CodeBuilder code)
    {
        import std.algorithm : substitute, splitter, skipOver, startsWith;
        import std.range     : chain;
        import std.uni       : toLower;
        import std.array     : array;

        // Find where the colour data starts
        auto dataByLine = colourData.splitter("\r\n");
        dataByLine.skipOver!(l => !l.startsWith(`"Colour Name"`));
        dataByLine.popFront(); // Skip over the "Colour Name" line.

        foreach(line; dataByLine)
        {
            // Line format: "Renese [Name]"[tab]R[tab]G[tab]B
            // Make the colour's name:
            // "Renese Azure" -> "azure"
            // "Renese Aero Blue" -> "aeroBlue"

            auto lineData   = line.splitter("\t");
            string fakeName = lineData.popReturn().substitute("\"", "", "Resene ", "", "JArena ", "").array.to!string;
            ubyte r         = lineData.popReturn().to!ubyte;
            ubyte g         = lineData.popReturn().to!ubyte;
            ubyte b         = lineData.popReturn().to!ubyte;
            assert(lineData.empty);

            // Fixup the name
            char[] name;
            auto nameSplit = fakeName.splitter(" ");
            name ~= nameSplit.popReturn().toLower();
            foreach(nameComp; nameSplit)
                name ~= nameComp;
        
            code.putf("Colour %s() { return Colour(%s, %s, %s, 255); }",
                      name, r, g, b);
        }
    }

    private auto popReturn(R)(ref R range)
    {
        auto val = range.front;
        range.popFront();
        return val;
    }
}
