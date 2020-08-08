using System;
using System.Collections.Generic;
using System.Linq;
namespace Editor_CSharp.Serial
{
	public class List_string_Serialiser : ITypeSerialiser
	{
		public void Serialise(ArchiveObject parent, Object obj, TypeChildInfo info)
		{
			ArchiveObject arc;
			if(!info.Flags.HasFlag(TypeFlags.IsMainValue))
			{
				arc = new ArchiveObject(info.Name ?? "NAME ME");
				parent.AddChild(arc);
			}
			else
				arc = parent;
			foreach(var val in (List<string>)obj)
			{
				arc.AddValueAs(val);
			}
		}
		public Object Deserialise(ArchiveObject obj, TypeChildInfo info)
		{
			ArchiveObject arc;
			var value = new List<string>();
			if(!info.Flags.HasFlag(TypeFlags.IsMainValue))
				arc = obj.ExpectChild(info.Name ?? "NAME ME");
			else
				arc = obj;
			foreach(var val in arc.Values)
			{
				value.Add(val.Get<string>());
			}
			return value;
		}
	}
}
