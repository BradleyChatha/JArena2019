using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Editor_CSharp.Serial
{
    public class NullValue
    { }

    public class ArchiveValue
    {
        public static readonly Type[] ValidTypes = 
        {
            typeof(bool),
            typeof(NullValue),
            typeof(List<byte>),
            typeof(List<ArchiveValue>),
            typeof(sbyte),
            typeof(byte),
            typeof(short),
            typeof(ushort),
            typeof(int),
            typeof(uint),
            typeof(long),
            typeof(ulong),
            typeof(string),
            typeof(float),
            typeof(double)
        };

        private Object _Value;
        public Type CurrentType { get; private set; }

        public static ArchiveValue Create<T>(T value)
        {
            var obj = new ArchiveValue();
            obj.SetValue<T>(value);

            return obj;
        }

        public T Get<T>()
        {
            EnforceValidType<T>();

            if(typeof(T) != this.CurrentType)
                throw new ArrayTypeMismatchException($"The currently stored type is {this.CurrentType.ToString()}, not a {typeof(T).ToString()}");

            return (T)this._Value;
        }

        public void SetValue<T>(T value)
        {
            EnforceValidType<T>();

            this.CurrentType = typeof(T);
            this._Value = value;
        }

        public bool Is<T>()
        {
            EnforceValidType<T>();
            return this.CurrentType == typeof(T);
        }

        private static void EnforceValidType<T>()
        {
            var type = typeof(T);
            if(ValidTypes.Count(t => t == type) == 0)
                throw InvalidArchiveTypeException.ForType<T>();
        }
    }

    [Serializable]
    public class InvalidArchiveTypeException : Exception
    {
        public InvalidArchiveTypeException() { }
        public InvalidArchiveTypeException(string message) : base(message) { }
        public InvalidArchiveTypeException(string message, Exception inner) : base(message, inner) { }
        protected InvalidArchiveTypeException(
          System.Runtime.Serialization.SerializationInfo info,
          System.Runtime.Serialization.StreamingContext context) : base(info, context) { }

        public static InvalidArchiveTypeException ForType<T>()
        {
            return new InvalidArchiveTypeException($"The type {typeof(T).ToString()} is not a valid archive value type.");
        }
    }
}
