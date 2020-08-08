using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Editor_CSharp.Serial
{
    public class ArchiveBinary : Archive
    {
        static readonly byte[] MAGIC_NUMBER = new byte[] { (byte)'J', (byte)'S', (byte)'E' };

        public ArchiveBinary()
        {
            this.Root = new ArchiveObject();
        }

        public override void LoadFromMemory(IEnumerable<byte> data)
        {
            var stream = new BinaryStream(data.ToArray());
            if(!stream.ReadBytes(3).SequenceEqual(MAGIC_NUMBER))
                throw new Exception("Invalid Magic Number");

            var crc    = (uint)stream.ReadInt32();
            var start  = stream.memory.Position;
            var length = stream.ReadInt32();

            stream.memory.Position = stream.memory.Position - 4;
            if((new Crc32()).Get<byte>(stream.ReadBytes(length + 4)) != crc)
                throw new Exception("CRC Mismatch. This is usually a sign that the data has been tampered with, or some kind of transport error occured.");

            stream.memory.Position = start;
            this.Root = this.loadObject(stream, true);
        }

        public override IEnumerable<byte> SaveToMemory()
        {
            var stream = new BinaryStream();

            stream.WriteBytes(MAGIC_NUMBER);
            stream.WriteInt32(0); // CRC reserved

            var start = stream.memory.Position;
            this.saveObject(stream, this.Root, true);
            var length = (stream.memory.Position - start);

            stream.memory.Position = start;
            var bytes = stream.ReadBytes((int)length);
            stream.memory.Position = start - 4;
            var crc = (new Crc32()).Get<byte>(bytes);
            stream.WriteInt32((int)crc);

            stream.memory.Position = 0;
            return stream.ReadBytes((int)stream.memory.Length);
        }

        enum DataType : byte
        {
            Bool,
            Null,
            UByteArray,
            ValueArray,
            Byte,
            UByte,
            Short,
            UShort,
            Int,
            UInt,
            Long,
            ULong,
            String,
            Float,
            Double,

            Object = 0xFE,
            Attribute = 0xFF
        }

        DataType getTypeFor(ArchiveValue value)
        {
            if (value.CurrentType == typeof(bool)) return DataType.Bool;
            else if (value.CurrentType == typeof(NullValue))     return DataType.Null;
            else if (value.CurrentType == typeof(List<byte>)) return DataType.UByteArray;
            else if (value.CurrentType == typeof(List<ArchiveValue>)) return DataType.ValueArray;
            else if (value.CurrentType == typeof(byte)) return DataType.Byte;
            else if (value.CurrentType == typeof(byte)) return DataType.UByte;
            else if (value.CurrentType == typeof(short)) return DataType.Short;
            else if (value.CurrentType == typeof(ushort)) return DataType.UShort;
            else if (value.CurrentType == typeof(int)) return DataType.Int;
            else if (value.CurrentType == typeof(uint)) return DataType.UInt;
            else if (value.CurrentType == typeof(long)) return DataType.Long;
            else if (value.CurrentType == typeof(ulong)) return DataType.ULong;
            else if (value.CurrentType == typeof(string)) return DataType.String;
            else if (value.CurrentType == typeof(float)) return DataType.Float;
            else if (value.CurrentType == typeof(double)) return DataType.Double;

            throw new NotSupportedException();
        }

        ArchiveValue loadValue(BinaryStream stream, DataType type)
        {
            switch (type)
            {       
                case DataType.Bool:
                return ArchiveValue.Create(stream.ReadBytes(1)[0] == 0 ? false : true);

                case DataType.Null:
                return ArchiveValue.Create(new NullValue());

                case DataType.Byte:
                return ArchiveValue.Create((sbyte)stream.ReadBytes(1)[0]);

                case DataType.UByte:
                return ArchiveValue.Create(stream.ReadBytes(1)[0]);
                    
                case DataType.Short:
                return ArchiveValue.Create(stream.ReadInt16());
                    
                case DataType.UShort:
                return ArchiveValue.Create((ushort)stream.ReadInt16());
                    
                case DataType.Int:
                return ArchiveValue.Create(stream.ReadInt32());
                    
                case DataType.UInt:
                return ArchiveValue.Create((uint)stream.ReadInt32());
                    
                case DataType.Long:
                return ArchiveValue.Create(stream.ReadInt64());
                    
                case DataType.ULong:
                return ArchiveValue.Create((ulong)stream.ReadInt64());
                                      
                    
                case DataType.Float:
                return ArchiveValue.Create(stream.ReadFloat());
                    
                case DataType.Double:
                return ArchiveValue.Create(stream.ReadDouble());

                case DataType.String:
                    var length = stream.ReadLengthBytes();
                    var values = new List<ArchiveValue>();
                    
                    return ArchiveValue.Create(System.Text.Encoding.UTF8.GetString(stream.ReadBytes(length)));

                case DataType.UByteArray:
                    length = stream.ReadLengthBytes();
                    values = new List<ArchiveValue>();
                    return ArchiveValue.Create(stream.ReadBytes(length));

                case DataType.ValueArray:
                    length = stream.ReadLengthBytes();
                    values = new List<ArchiveValue>();
                    for(var i = 0; i < length; i++)
                    {
                        var type2 = stream.ReadBytes(1)[0];
                        values.Add(this.loadValue(stream, (DataType)type2));
                    }
                    return ArchiveValue.Create(values);

                default:
                    throw new InvalidOperationException($"{type}");
            }
        }

        ArchiveObject loadObject(BinaryStream stream, bool isRoot = false)
        {
            var length = stream.ReadInt32();
            var start = stream.memory.Position;
            var name = (isRoot) ? "" : System.Text.Encoding.UTF8.GetString(stream.ReadBytes(stream.ReadLengthBytes()));
            var obj = new ArchiveObject(name);

            while (true)
            {
                if(stream.memory.Position > start + length)
                     throw new Exception("Malformed data. Attempted to read past an object's data.");

                if (stream.memory.Position == start + length)
                    break;

                var type = stream.ReadBytes(1)[0];
                switch (type)
                {
                    case (byte)DataType.Bool:
                    case (byte)DataType.Null:
                    case (byte)DataType.UByteArray:
                    case (byte)DataType.ValueArray:
                    case (byte)DataType.Byte:
                    case (byte)DataType.UByte:
                    case (byte)DataType.Short:
                    case (byte)DataType.UShort:
                    case (byte)DataType.Int:
                    case (byte)DataType.UInt:
                    case (byte)DataType.Long:
                    case (byte)DataType.ULong:
                    case (byte)DataType.String:
                    case (byte)DataType.Float:
                    case (byte)DataType.Double:
                    obj.AddValue(this.loadValue(stream, (DataType)type));
                    break;

                    case (byte)DataType.Object:
                    obj.AddChild(this.loadObject(stream));
                    break;

                    case (byte)DataType.Attribute:
                    var attribName = System.Text.Encoding.UTF8.GetString(stream.ReadBytes(stream.ReadLengthBytes()));
                    obj.SetAttribute(attribName, this.loadValue(stream, (DataType)stream.ReadBytes(1)[0]));
                    break;

                    default:
                        throw new Exception("Malformed data. Unknown entry data type: ");
                }
            }

            return obj;
        }

        void saveEntry(BinaryStream stream, DataType type, Action saver, bool hasLength, bool isRoot = false)
        {
            if(!isRoot)
                stream.WriteInt8((byte)type);

            if(hasLength)
                stream.WriteInt32(0); // Length, reserved

            var start = stream.memory.Position;
            saver();

            if(hasLength)
            {
                var length = (stream.memory.Position - start);
                //assert(stream.position >= start);

                stream.memory.Position = start - 4;
                stream.WriteInt32((int)length);
                stream.memory.Position = stream.memory.Length;
            }
        }

        void saveObject(BinaryStream stream, ArchiveObject obj, bool isRoot = false)
        {
            this.saveEntry(stream, DataType.Object, () =>
            {
                if (!isRoot)
                {
                    stream.WriteLengthBytes(obj.Name.Length);
                    stream.WriteBytes(System.Text.Encoding.UTF8.GetBytes(obj.Name));
                }

                foreach (var attrib in obj.Attributes)
                    this.saveAttribute(stream, attrib);

                foreach (var value in obj.Values)
                    this.saveValue(stream, value);

                foreach (var child in obj.Children)
                    this.saveObject(stream, child);
            }, true, isRoot);
        }

        void saveAttribute(BinaryStream stream, ArchiveObject.Attribute attrib)
        {
            this.saveEntry(stream, DataType.Attribute, () =>
            {
                stream.WriteLengthBytes(attrib.Name.Length);
                stream.WriteBytes(System.Text.Encoding.UTF8.GetBytes(attrib.Name));
                this.saveValue(stream, attrib.Value);
            }, false);
        }

        void saveValue(BinaryStream stream, ArchiveValue value)
        {
            var type = this.getTypeFor(value);
            this.saveEntry(stream, type, () =>
            {
                //assert(type != DataType.Object);
                //assert(type != DataType.Attribute);
                switch (type)
                {
                    case DataType.Object:
                    case DataType.Attribute:
                    case DataType.Null: break;
                    case DataType.Bool: stream.WriteInt8(value.Get<bool>() ? (byte)1 : (byte)0); break;
                    case DataType.Byte: stream.WriteInt8((byte)value.Get<sbyte>()); break;
                    case DataType.UByte: stream.WriteInt8(value.Get<byte>()); break;
                    case DataType.Short: stream.WriteInt16(value.Get<short>()); break;
                    case DataType.UShort: stream.WriteInt16((short)value.Get<ushort>()); break;
                    case DataType.Int: stream.WriteInt32(value.Get<int>()); break;
                    case DataType.UInt: stream.WriteInt32((int)value.Get<uint>()); break;
                    case DataType.Long: stream.WriteInt64(value.Get<long>()); break;
                    case DataType.ULong: stream.WriteInt64((long)value.Get<ulong>()); break;
                    case DataType.Float: stream.WriteFloat(value.Get<float>()); break;
                    case DataType.Double: stream.WriteDouble(value.Get<double>()); break;

                    case DataType.UByteArray:
                        var arr = value.Get<List<byte>>();
                        stream.WriteLengthBytes(arr.Count);
                        stream.WriteBytes(arr.ToArray());
                        break;

                    case DataType.String:
                        var arr2 = value.Get<string>();
                        stream.WriteLengthBytes(arr2.Length);
                        stream.WriteBytes(System.Text.Encoding.UTF8.GetBytes(arr2));
                        break;

                    case DataType.ValueArray:
                        var arr3 = value.Get<List<ArchiveValue>>();
                        stream.WriteLengthBytes(arr3.Count);

                        foreach (var val in arr3)
                            this.saveValue(stream, val);
                        break;
                }
            }, false);
        }
    }
}
