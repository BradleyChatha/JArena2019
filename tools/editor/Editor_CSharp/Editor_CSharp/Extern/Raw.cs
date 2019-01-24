using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using Editor_CSharp.Serial;

namespace Editor_CSharp.Extern
{
    [StructLayout(LayoutKind.Sequential)]
    public struct ByteSlice
    {
        // I hope to god this is consistent between compilers T.T
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
        public static extern void jengine_editor_init(ref ByteSlice onError);

        [DllImport("editor.dll", CallingConvention = CallingConvention.Cdecl)]
        public static extern void jengine_editor_update(ref ByteSlice onError);

        [DllImport("editor.dll", CallingConvention = CallingConvention.Cdecl)]
        public static extern void jengine_editor_openUIFile([MarshalAs(UnmanagedType.LPStr)] string path,
                                                                                             int pathLength,
                                                                                             ref ByteSlice data,
                                                                                             ref ByteSlice onError
                                                            );

        [DllImport("editor.dll", CallingConvention = CallingConvention.Cdecl)]
        public static extern void jengine_editor_getDefinition([MarshalAs(UnmanagedType.LPStr)] string controlName,
                                                                                                int nameLength,
                                                                                                ref ByteSlice data,
                                                                                                ref ByteSlice onError
                                                              );
    }

    public static class SliceExtension
    {
        public static void ThrowExceptionIfExists(this ByteSlice slice)
        {
            if (slice.Length > 0)
            {
                var archive = new ArchiveBinary();
                archive.LoadFromMemory(slice.Dup());
                var error = Serialiser.Deserialise<ExceptionInfo>(archive.Root);

                var message = $"{error.message}\nTrace:\n{error.stackTrace}";
                MessageBox.Show(message, "Exception", MessageBoxButton.OK, MessageBoxImage.Error);
                throw new EditorException(message);
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
