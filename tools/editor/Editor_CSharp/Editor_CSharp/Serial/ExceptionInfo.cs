using System;
using System.Collections.Generic;
using System.Linq;
namespace Editor_CSharp.Serial
{
	public class ExceptionInfo
	{
		public ExceptionInfo()
		{
		}
		public string stackTrace;
		public string message;
	}
	public class ExceptionInfoSerialiser : ITypeSerialiser
	{
		public void Serialise(ArchiveObject parent, Object obj, TypeChildInfo info)
		{
			var retObj = new ArchiveObject(info.Name ?? "ExceptionInfo");
			var value = (ExceptionInfo)obj;
			Serialiser.Serialise(retObj, value.stackTrace, new TypeChildInfo(){ Name = "stackTrace", Flags = TypeFlags.None });
			Serialiser.Serialise(retObj, value.message, new TypeChildInfo(){ Name = "message", Flags = TypeFlags.None });
			parent.AddChild(retObj);
		}
		public Object Deserialise(ArchiveObject obj, TypeChildInfo info)
		{
			if(obj.Name != (info.Name ?? "ExceptionInfo"))
				obj = obj.ExpectChild(info.Name ?? "ExceptionInfo");
			var value = new ExceptionInfo();
			value.stackTrace = Serialiser.Deserialise<string>(obj, new TypeChildInfo(){ Name = "stackTrace", Flags = TypeFlags.None });
			value.message = Serialiser.Deserialise<string>(obj, new TypeChildInfo(){ Name = "message", Flags = TypeFlags.None });
			return value;
		}
	}
}
