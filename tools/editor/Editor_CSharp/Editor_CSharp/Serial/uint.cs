using System;
using System.Collections.Generic;
using System.Linq;
namespace Editor_CSharp.Serial
{
	public class uintSerialiser : ITypeSerialiser
	{
		public void Serialise(ArchiveObject parent, Object obj, TypeChildInfo info)
		{
			if(info.Flags.HasFlag(TypeFlags.IsMainValue))
				parent.AddValueAs<uint>((uint)obj);
			else if(info.Flags.HasFlag(TypeFlags.IsAttribute))
				parent.SetAttributeAs<uint>(info.Name ?? "NAME ME", (uint)obj);
			else
			{
				var arc = new ArchiveObject(info.Name ?? "NAME ME");
				arc.AddValueAs<uint>((uint)obj);
				parent.AddChild(arc);
			}
		}
		public Object Deserialise(ArchiveObject obj, TypeChildInfo info)
		{
			if(info.Flags.HasFlag(TypeFlags.IsMainValue))
				return obj.ExpectValueAs<uint>(0);
			else if(info.Flags.HasFlag(TypeFlags.IsAttribute))
				return obj.ExpectAttributeAs<uint>(info.Name ?? "NAME ME");
			else
				return obj.ExpectChild(info.Name ?? "NAME ME").ExpectValueAs<uint>(0);
		}
	}
}
