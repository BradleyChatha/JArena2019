import core.sys.windows.windows;
import core.sys.windows.dll;

import editor.core;
import jaster.serialise;

__gshared HINSTANCE g_hInst;

version(dll)
{
	extern (Windows)
	BOOL DllMain(HINSTANCE hInstance, ULONG ulReason, LPVOID pvReserved)
	{
		switch (ulReason)
		{
			case DLL_PROCESS_ATTACH:
				if(g_hInst != HINSTANCE.init)
					return false;

				g_hInst = hInstance;
				dll_process_attach( hInstance, true );
				break;

			case DLL_PROCESS_DETACH:
				dll_process_detach( hInstance, true );
				break;

			case DLL_THREAD_ATTACH:
				dll_thread_attach( true, true );
				break;

			case DLL_THREAD_DETACH:
				dll_thread_detach( true, true );
				break;

			default: break;
		}
		return true;
	}
}
else version(generator)
{
	void main()
	{
		import jarena.gameplay;
		CSharpGenerator.genFilesForTypes!(ExceptionInfo, DataBinder.ControlDef)("../Editor_CSharp/Editor_CSharp/Serial", "Editor_CSharp.Serial");
	}
}