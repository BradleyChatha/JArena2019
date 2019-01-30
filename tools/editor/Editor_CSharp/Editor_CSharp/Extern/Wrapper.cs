using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.IO;

using Editor_CSharp.Serial;

namespace Editor_CSharp.Extern
{
    public static class Editor
    {
        private static Thread _engineThread;

        private static void ThreadMain()
        {
            var errorInfo = new ByteSlice();
            EditorRaw.jengine_editor_init(ref errorInfo);
            errorInfo.ThrowExceptionIfExists();

            while(true)
            {
                EditorRaw.jengine_editor_update(ref errorInfo);
                errorInfo.ThrowExceptionIfExists();

                Thread.Yield();
            }
        }

        public static void Init()
        {
            if(IntPtr.Size != 4)
                throw new Exception("Only x86 is supported right now. The editor shouldn't get *anywhere near* the memory limit for a 32-bit program, so this is fine.");

            if(_engineThread != null)
                return;

            _engineThread = new Thread(Editor.ThreadMain);
            _engineThread.Start();
        }

        public static void CloseThreads()
        {
            if(_engineThread != null && _engineThread.IsAlive)
                _engineThread.Abort();
        }

        public static ArchiveObject OpenUIFile(string path)
        {
            var data    = new ByteSlice();
            var onError = new ByteSlice();
            EditorRaw.jengine_editor_openUIFile(path, path.Length, ref data, ref onError);
            onError.ThrowExceptionIfExists();

            var binary = new ArchiveBinary();
            binary.LoadFromMemory(data.Dup());

            return binary.Root.GetChild("UI:view");
        }

        public static ControlDef GetDefinitionFor(string controlName)
        {
            var data    = new ByteSlice();
            var onError = new ByteSlice();
            EditorRaw.jengine_editor_getDefinition(controlName, controlName.Length, ref data, ref onError);
            onError.ThrowExceptionIfExists();

            var binary = new ArchiveBinary();
            binary.LoadFromMemory(data.Dup());

            return Serialiser.Deserialise<ControlDef>(binary.Root);
        }

        public static void SaveObjectToFile(string path, ArchiveObject obj, bool isRoot = true)
        {
            var binary = new ArchiveBinary();
            Editor.AddToOrAsRoot(binary.Root, obj, isRoot);

            var data    = new ByteSliceFromManaged(binary.SaveToMemory());
            var onError = new ByteSlice();
            EditorRaw.jengine_editor_saveFile(path, path.Length, data, ref onError);
            data.Dispose();
            onError.ThrowExceptionIfExists();
        }

        public static void ChangeView(ArchiveObject viewRoot, bool isRoot = true)
        {
            var binary  = new ArchiveBinary();
            var onError = new ByteSlice();
            Editor.AddToOrAsRoot(binary.Root, viewRoot, isRoot);

            var data = new ByteSliceFromManaged(binary.SaveToMemory());
            EditorRaw.jengine_editor_changeView(data, ref onError);
            data.Dispose();
            onError.ThrowExceptionIfExists();
        }

        private static void AddToOrAsRoot(ArchiveObject parent, ArchiveObject obj, bool isRoot)
        {
            if (isRoot)
            {
                foreach (var val in obj.Values)
                    parent.AddValue(val);
                foreach (var prop in obj.Attributes)
                    parent.SetAttribute(prop.Name, prop.Value);
                foreach (var child in obj.Children)
                    parent.AddChild(child);
            }
            else
                parent.AddChild(obj);
        }
    }
}
