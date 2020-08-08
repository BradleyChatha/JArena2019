using System;
using System.Collections.Generic;
using System.Linq;
namespace Editor_CSharp.Serial
{
	public class ControlDef
	{
		public ControlDef()
		{
			this.bindings = new List<BindingDef>();
		}
		public List<BindingDef> bindings;
		public string name;
	}
	public class ControlDefSerialiser : ITypeSerialiser
	{
		public void Serialise(ArchiveObject parent, Object obj, TypeChildInfo info)
		{
			var retObj = new ArchiveObject(info.Name ?? "ControlDef");
			var value = (ControlDef)obj;
			Serialiser.Serialise(retObj, value.bindings, new TypeChildInfo(){ Name = "bindings", Flags = TypeFlags.None });
			Serialiser.Serialise(retObj, value.name, new TypeChildInfo(){ Name = "name", Flags = TypeFlags.None });
			parent.AddChild(retObj);
		}
		public Object Deserialise(ArchiveObject obj, TypeChildInfo info)
		{
			if(obj.Name != (info.Name ?? "ControlDef"))
				obj = obj.ExpectChild(info.Name ?? "ControlDef");
			var value = new ControlDef();
			value.bindings = Serialiser.Deserialise<List<BindingDef>>(obj, new TypeChildInfo(){ Name = "bindings", Flags = TypeFlags.None });
			value.name = Serialiser.Deserialise<string>(obj, new TypeChildInfo(){ Name = "name", Flags = TypeFlags.None });
			return value;
		}
	}
}
