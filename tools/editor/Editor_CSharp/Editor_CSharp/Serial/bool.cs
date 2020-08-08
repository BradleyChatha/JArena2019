using System;
using System.Collections.Generic;
using System.Linq;
namespace Editor_CSharp.Serial
{
	public class boolSerialiser : ITypeSerialiser
	{
		public void Serialise(ArchiveObject parent, Object obj, TypeChildInfo info)
		{
			if(info.Flags.HasFlag(TypeFlags.IsMainValue))
				parent.AddValueAs<bool>((bool)obj);
			else if(info.Flags.HasFlag(TypeFlags.IsAttribute))
				parent.SetAttributeAs<bool>(info.Name ?? "NAME ME", (bool)obj);
			else
			{
				var arc = new ArchiveObject(info.Name ?? "NAME ME");
				arc.AddValueAs<bool>((bool)obj);
				parent.AddChild(arc);
			}
		}
		public Object Deserialise(ArchiveObject obj, TypeChildInfo info)
		{
			if(info.Flags.HasFlag(TypeFlags.IsMainValue))
				return obj.ExpectValueAs<bool>(0);
			else if(info.Flags.HasFlag(TypeFlags.IsAttribute))
				return obj.ExpectAttributeAs<bool>(info.Name ?? "NAME ME");
			else
				return obj.ExpectChild(info.Name ?? "NAME ME").ExpectValueAs<bool>(0);
		}
	}
}
