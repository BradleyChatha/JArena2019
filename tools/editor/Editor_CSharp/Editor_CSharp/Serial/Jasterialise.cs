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
		}
	}
}
