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

            while(true) Thread.Sleep(1000);
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
    }
}
