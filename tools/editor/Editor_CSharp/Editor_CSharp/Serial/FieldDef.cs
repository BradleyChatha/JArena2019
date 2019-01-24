using System;
using System.Collections.Generic;
using System.Linq;
namespace Editor_CSharp.Serial
{
	public class FieldDef
	{
		public FieldDef()
		{
		}
		public string outputSubtype;
		public uint inputStaticLength;
		public string outputType;
		public string name;
		public string inputType;
		public uint outputStaticLength;
		public string inputSubtype;
	}
	public class FieldDefSerialiser : ITypeSerialiser
	{
		public void Serialise(ArchiveObject parent, Object obj, TypeChildInfo info)
		{
			var retObj = new ArchiveObject(info.Name ?? "FieldDef");
			var value = (FieldDef)obj;
			Serialiser.Serialise(retObj, value.outputSubtype, new TypeChildInfo(){ Name = "outputSubtype", Flags = TypeFlags.None });
			Serialiser.Serialise(retObj, value.inputStaticLength, new TypeChildInfo(){ Name = "inputStaticLength", Flags = TypeFlags.None });
			Serialiser.Serialise(retObj, value.outputType, new TypeChildInfo(){ Name = "outputType", Flags = TypeFlags.None });
			Serialiser.Serialise(retObj, value.name, new TypeChildInfo(){ Name = "name", Flags = TypeFlags.None });
			Serialiser.Serialise(retObj, value.inputType, new TypeChildInfo(){ Name = "inputType", Flags = TypeFlags.None });
			Serialiser.Serialise(retObj, value.outputStaticLength, new TypeChildInfo(){ Name = "outputStaticLength", Flags = TypeFlags.None });
			Serialiser.Serialise(retObj, value.inputSubtype, new TypeChildInfo(){ Name = "inputSubtype", Flags = TypeFlags.None });
			parent.AddChild(retObj);
		}
		public Object Deserialise(ArchiveObject obj, TypeChildInfo info)
		{
			if(obj.Name != (info.Name ?? "FieldDef"))
				obj = obj.ExpectChild(info.Name ?? "FieldDef");
			var value = new FieldDef();
			value.outputSubtype = Serialiser.Deserialise<string>(obj, new TypeChildInfo(){ Name = "outputSubtype", Flags = TypeFlags.None });
			value.inputStaticLength = Serialiser.Deserialise<uint>(obj, new TypeChildInfo(){ Name = "inputStaticLength", Flags = TypeFlags.None });
			value.outputType = Serialiser.Deserialise<string>(obj, new TypeChildInfo(){ Name = "outputType", Flags = TypeFlags.None });
			value.name = Serialiser.Deserialise<string>(obj, new TypeChildInfo(){ Name = "name", Flags = TypeFlags.None });
			value.inputType = Serialiser.Deserialise<string>(obj, new TypeChildInfo(){ Name = "inputType", Flags = TypeFlags.None });
			value.outputStaticLength = Serialiser.Deserialise<uint>(obj, new TypeChildInfo(){ Name = "outputStaticLength", Flags = TypeFlags.None });
			value.inputSubtype = Serialiser.Deserialise<string>(obj, new TypeChildInfo(){ Name = "inputSubtype", Flags = TypeFlags.None });
			return value;
		}
	}
}
