using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace Editor_CSharp.Serial
{
    public class BinaryStream
    {
        public MemoryStream memory;
        public BinaryWriter writer;
        public BinaryReader reader;

        public BinaryStream(byte[] bytes = null)
        {
            this.memory = new MemoryStream();
            this.writer = new BinaryWriter(this.memory);
            this.reader = new BinaryReader(this.memory);
            
            if(bytes != null)
            {
                this.writer.Write(bytes);
                this.writer.Seek(0, SeekOrigin.Begin);
            }
        }

        public byte[] ReadBytes(int amount)
        {
            if(amount == 0)
                return new byte[]{ };

            if(this.memory.Position + amount > this.memory.Length)
                throw new EndOfStreamException("Attempted to read past the stream.");
            
            return this.reader.ReadBytes(amount);
        }

        public int ReadLengthBytes()
        {
            var info = this.ReadInt8() & 0b1100_0000; // NOTE: This only works because numbers are in big-endian
            this.memory.Seek(-1, SeekOrigin.Current);

            if (info == 0)
                return (int)this.ReadInt8();
            else if (info == 0b0100_0000)
                return this.ReadInt16() & 0b00111111_11111111;
            else if (info == 0b1000_0000)
                return this.ReadInt32() & 0b00111111_11111111_11111111_11111111;
            else
                throw new Exception("Length size info 0b1100_0000 is not used right now.");
        }

        public byte ReadInt8()
        {
            return this.ReadBytes(1)[0];
        }

        public short ReadInt16()
        {
            var bytes = this.ReadBytes(2);
            Array.Reverse(bytes);
            return BitConverter.ToInt16(bytes, 0);
        }

        public int ReadInt32()
        {
            var bytes = this.ReadBytes(4);
            Array.Reverse(bytes);
            return BitConverter.ToInt32(bytes, 0);
        }

        public long ReadInt64()
        {
            var bytes = this.ReadBytes(8);
            Array.Reverse(bytes);
            return BitConverter.ToInt64(bytes, 0);
        }

        public float ReadFloat()
        {
            var bytes = this.ReadBytes(4);
            Array.Reverse(bytes);
            return BitConverter.ToSingle(bytes, 0);
        }

        public double ReadDouble()
        {
            var bytes = this.ReadBytes(8);
            Array.Reverse(bytes);
            return BitConverter.ToDouble(bytes, 0);
        }

        public void WriteBytes(byte[] bytes)
        {
            this.writer.Write(bytes);
        }

        public void WriteLengthBytes(int length)
        {
            // Last two bits are reserved for size info.
            // 00 = Length is one byte.
            // 01 = Length is two bytes.
            // 10 = Length is four bytes.
            if(length > 0b00111111_11111111_11111111_11111111)
                throw new ArgumentOutOfRangeException("length", "Length is too much");

            if (length <= 0b00111111) // Single byte
                this.WriteInt8((byte)length);
            else if (length <= 0b00111111_11111111) // Two bytes
            {
                length |= 0b01000000_00000000;
                this.WriteInt16((short)length);
            }
            else // Four bytes
            {
                unchecked
                {
                    length |= (int)0b10000000_00000000_00000000_00000000;
                }
                this.WriteInt32((int)length);
            }
        }

        public void WriteInt8(byte b)
        {
            this.WriteBytes(new byte[]{ b });
        }

        public void WriteInt16(short s)
        {
            var bytes = BitConverter.GetBytes(s);
            Array.Reverse(bytes);
            this.WriteBytes(bytes);
        }

        public void WriteInt32(int i)
        {
            var bytes = BitConverter.GetBytes(i);
            Array.Reverse(bytes);
            this.WriteBytes(bytes);
        }

        public void WriteInt64(long i)
        {
            var bytes = BitConverter.GetBytes(i);
            Array.Reverse(bytes);
            this.WriteBytes(bytes);
        }

        public void WriteFloat(float i)
        {
            var bytes = BitConverter.GetBytes(i);
            Array.Reverse(bytes);
            this.WriteBytes(bytes);
        }

        public void WriteDouble(double i)
        {
            var bytes = BitConverter.GetBytes(i);
            Array.Reverse(bytes);
            this.WriteBytes(bytes);
        }
    }
}
