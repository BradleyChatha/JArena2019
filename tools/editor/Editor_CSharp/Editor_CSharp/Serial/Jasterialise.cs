using System;
using System.Collections.Generic;
namespace Editor_CSharp.Serial
{
	public static class Jasterialise
	{
		public static void RegisterSerialisers()
		{
			Serialiser.Register<ExceptionInfo>(new ExceptionInfoSerialiser());
			Serialiser.Register<string>(new stringSerialiser());
			Serialiser.Register<ControlDef>(new ControlDefSerialiser());
			Serialiser.Register<List<BindingDef>>(new List_BindingDef_Serialiser());
			Serialiser.Register<BindingDef>(new BindingDefSerialiser());
			Serialiser.Register<List<FieldDef>>(new List_FieldDef_Serialiser());
			Serialiser.Register<FieldDef>(new FieldDefSerialiser());
			Serialiser.Register<uint>(new uintSerialiser());
			Serialiser.Register<bool>(new boolSerialiser());
			Serialiser.Register<List<string>>(new List_string_Serialiser());
		}
	}
}
