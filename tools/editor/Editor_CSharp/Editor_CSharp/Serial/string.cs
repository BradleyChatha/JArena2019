using System;
using System.Collections.Generic;
using System.Linq;
namespace Editor_CSharp.Serial
{
	public class stringSerialiser : ITypeSerialiser
	{
		public void Serialise(ArchiveObject parent, Object obj, TypeChildInfo info)
		{
			if(info.Flags.HasFlag(TypeFlags.IsMainValue))
				parent.AddValueAs<string>((string)obj);
			else if(info.Flags.HasFlag(TypeFlags.IsAttribute))
				parent.SetAttributeAs<string>(info.Name ?? "NAME ME", (string)obj);
			else
			{
				var arc = new ArchiveObject(info.Name ?? "NAME ME");
				arc.AddValueAs<string>((string)obj);
				parent.AddChild(arc);
			}
		}
		public Object Deserialise(ArchiveObject obj, TypeChildInfo info)
		{
			if(info.Flags.HasFlag(TypeFlags.IsMainValue))
				return obj.ExpectValueAs<string>(0);
			else if(info.Flags.HasFlag(TypeFlags.IsAttribute))
				return obj.ExpectAttributeAs<string>(info.Name ?? "NAME ME");
			else
				return obj.ExpectChild(info.Name ?? "NAME ME").ExpectValueAs<string>(0);
		}
	}
}
