using System;
using System.Collections.Generic;
using System.Linq;
namespace Editor_CSharp.Serial
{
	public class List_BindingDef_Serialiser : ITypeSerialiser
	{
		public void Serialise(ArchiveObject parent, Object obj, TypeChildInfo info)
		{
			ArchiveObject arc;
			if(info.Flags.HasFlag(TypeFlags.ArrayAsObject))
			{
				arc = new ArchiveObject(info.Name ?? "NAME ME");
				parent.AddChild(arc);
			}
			else
				arc = parent;
			foreach(var val in (List<BindingDef>)obj)
			{
				Serialiser.Serialise(arc, val, new TypeChildInfo());
			}
		}
		public Object Deserialise(ArchiveObject obj, TypeChildInfo info)
		{
			ArchiveObject arc;
			var value = new List<BindingDef>();
			if(info.Flags.HasFlag(TypeFlags.ArrayAsObject))
				arc = obj.ExpectChild(info.Name ?? "NAME ME");
			else
				arc = obj;
			foreach(var val in arc.Children.Where(c => c.Name == "BindingDef"))
			{
				value.Add(Serialiser.Deserialise<BindingDef>(val, new TypeChildInfo()));
			}
			return value;
		}
	}
}
