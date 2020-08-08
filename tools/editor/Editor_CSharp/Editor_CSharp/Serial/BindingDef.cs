using System;
using System.Collections.Generic;
using System.Linq;
namespace Editor_CSharp.Serial
{
	public class BindingDef
	{
		public BindingDef()
		{
			this.fields = new List<FieldDef>();
		}
		public string targetName;
		public List<FieldDef> fields;
		public string name;
	}
	public class BindingDefSerialiser : ITypeSerialiser
	{
		public void Serialise(ArchiveObject parent, Object obj, TypeChildInfo info)
		{
			var retObj = new ArchiveObject(info.Name ?? "BindingDef");
			var value = (BindingDef)obj;
			Serialiser.Serialise(retObj, value.targetName, new TypeChildInfo(){ Name = "targetName", Flags = TypeFlags.None });
			Serialiser.Serialise(retObj, value.fields, new TypeChildInfo(){ Name = "fields", Flags = TypeFlags.None });
			Serialiser.Serialise(retObj, value.name, new TypeChildInfo(){ Name = "name", Flags = TypeFlags.None });
			parent.AddChild(retObj);
		}
		public Object Deserialise(ArchiveObject obj, TypeChildInfo info)
		{
			if(obj.Name != (info.Name ?? "BindingDef"))
				obj = obj.ExpectChild(info.Name ?? "BindingDef");
			var value = new BindingDef();
			value.targetName = Serialiser.Deserialise<string>(obj, new TypeChildInfo(){ Name = "targetName", Flags = TypeFlags.None });
			value.fields = Serialiser.Deserialise<List<FieldDef>>(obj, new TypeChildInfo(){ Name = "fields", Flags = TypeFlags.None });
			value.name = Serialiser.Deserialise<string>(obj, new TypeChildInfo(){ Name = "name", Flags = TypeFlags.None });
			return value;
		}
	}
}
