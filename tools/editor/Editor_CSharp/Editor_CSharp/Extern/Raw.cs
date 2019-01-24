﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using Editor_CSharp.Serial;

namespace Editor_CSharp.Extern
{
    [StructLayout(LayoutKind.Sequential)]
    public struct Slice
    {
        public int Length;
        public IntPtr Ptr;

        public byte[] Dup()
        {
            if(Length < 0)
                throw new Exception("Array is too large.");

            byte[] bytes = new byte[this.Length];
            Marshal.Copy(this.Ptr, bytes, 0, this.Length);
            return bytes;
        }
    }

    public static class EditorRaw
    {
        [DllImport("editor.dll", CallingConvention = CallingConvention.Cdecl)]
        public static extern void jengine_editor_init(ref Slice onError);
    }

    public static class SliceExtension
    {
        public static void ThrowExceptionIfExists(this Slice slice)
        {
            if (slice.Length > 0)
            {
                var archive = new ArchiveBinary();
                archive.LoadFromMemory(slice.Dup());
                var error = Serialiser.Deserialise<ExceptionInfo>(archive.Root);

                throw new EditorException($"{error.message}\nTrace:\n{error.stackTrace}");
            }
        }
    }

    [Serializable]
    public class EditorException : Exception
    {
        public EditorException() { }
        public EditorException(string message) : base(message) { }
        public EditorException(string message, Exception inner) : base(message, inner) { }
        protected EditorException(
          System.Runtime.Serialization.SerializationInfo info,
          System.Runtime.Serialization.StreamingContext context) : base(info, context) { }
    }
}
