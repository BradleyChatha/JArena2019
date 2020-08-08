using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Editor_CSharp.Serial
{
    public interface ITypeSerialiser
    {
        void Serialise(ArchiveObject parent, Object obj, TypeChildInfo info);
        Object Deserialise(ArchiveObject obj, TypeChildInfo info);
    }

    [Flags]
    public enum TypeFlags
    {
        None = 0,
        IsMainValue = 1 << 0,
        IsAttribute = 1 << 1,
        ArrayAsObject = 1 << 2,
        EnumAsValue = 1 << 3
    }

    public class TypeChildInfo
    {
        public TypeFlags Flags;
        public string Name;
    }

    public static class Serialiser
    {
        static Dictionary<Type, ITypeSerialiser> _serialisers;

        public static void Register<T>(ITypeSerialiser serialiser)
        {
            if(_serialisers == null)
                _serialisers = new Dictionary<Type, ITypeSerialiser>();

            if(serialiser == null)
                throw new ArgumentNullException("serialiser");

            if(_serialisers.ContainsKey(typeof(T)))
                throw new InvalidOperationException($"A serialiser for {typeof(T).ToString()} already exists.");

            _serialisers[typeof(T)] = serialiser;
        }

        public static void Serialise<T>(ArchiveObject root, T value, TypeChildInfo info = null)
        {
            _serialisers[typeof(T)].Serialise(root, value, info ?? new TypeChildInfo());
        }

        public static T Deserialise<T>(ArchiveObject obj, TypeChildInfo info = null)
        {
            return (T)_serialisers[typeof(T)].Deserialise(obj, info ?? new TypeChildInfo());
        }
    }
}
