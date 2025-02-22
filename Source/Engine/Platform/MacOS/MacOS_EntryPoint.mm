// ===================================================================
//	Copyright (C) 2013 Tim Leonard
// ===================================================================
#ifdef PLATFORM_MACOS

#include "Engine/Platform/MacOS/MacOS_Platform.h"
#include "Generic/Helper/StringHelper.h"

#include "Generic/Threads/Thread.h"
#include "Generic/Threads/MacOS/MacOS_Thread.h"

#include "Engine/Engine/GameEngine.h"
#include "Engine/Engine/GameRunner.h"

#include "Engine/Renderer/Textures/PNG/PNGPixelmapFactory.h"
#include "Engine/Renderer/Text/FreeType/FreeType_FontFactory.h"
#include "Engine/IO/MacOS/MacOS_FileStreamFactory.h"
#include "Engine/Audio/FMod/FMod_SoundFactory.h"

#include "Generic/Math/Random.h"

#include "Engine/Version.h"

#include <signal.h>
#include <pthread.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/wait.h>
#include <setjmp.h>
#include <stdarg.h>
#include <cstdio>
#include <fcntl.h>
#include <unistd.h>
#include <dirent.h>
#include <math.h>
#include <execinfo.h>
#include <dlfcn.h>
#include <cxxabi.h>
#include <time.h>
#include <CoreServices/CoreServices.h>
#include <mach/clock.h>
#include <mach/mach.h>
#include <mach/mach_time.h>
#include <mach-o/dyld.h>
#include <time.h>
#include <uuid/uuid.h>
#include <ctime>
#include <stdlib.h>

jmp_buf		g_error_recovery_longjmp;
pthread_t	g_main_thread;
char*		g_executable_file_path		= NULL;

void Signal_Termination_Handler(int sig)
{
	DBG_LOG("Recieved console close callback. Terminating game.");
	if (GameEngine::Try_Get())
	{
		GameEngine::Get()->Stop();
	}
}

void Signal_Handler(int sig)
{
	Platform* platform = Platform::Get();

    DBG_LOG("~~~~~~~~~~~~ UNHANDLED EXCEPTION OCCURRED ~~~~~~~~~~~");

	// TODO: Make dump file.

	// Dump stack trace.
	DBG_LOG("");
	DBG_LOG("Call Stack:");

	StackFrame frames[256];
	int frameCount = platform->Get_Stack_Trace(frames, 256);
	for (int i = 0; i < frameCount; i++)
	{
		StackFrame& frame = frames[i];		
		
		DecodedStackFrame output;
		platform->Resolve_Stack_Frame_Info(frame, output);

		DBG_LOG("[%i] %s (%i): %s", i, output.File, output.Line, output.Name); 
	}

	DBG_LOG("");
	
	// Bail out!
	_exit(1);

	/*
	// We only try to recover from the first unhandled exception.
	static bool g_recovered_from_unhandled_exception = false;
	if (g_recovered_from_unhandled_exception == true)
	{
		DBG_LOG("As this is a secondary unhandled exception, game will now abort.")
		exit(0);
	    return;
	}
	g_recovered_from_unhandled_exception = true;
	
	// Bail the fuck out.
    // We use this to long jump back to the point after PlatformMain is called
    // so we can deinitialize everything.
	if (pthread_equal(pthread_self(), g_main_thread))
	{
	    DBG_LOG("Attempting recovery through longjmp ...");
		longjmp(g_error_recovery_longjmp, 1);
	}
	*/

    return;
}

void Install_Signal_Handler()
{
	// Alternate stack signal handler dosen't seem to work right on SIGSEGV's :(
	/*
	stack_t ss = {};
	memset(&ss, 0, sizeof(ss));
	ss.ss_sp	= (void*)g_signal_handler_stack;
	ss.ss_size	= SIGSTKSZ;
	ss.ss_flags = 0;

	if (sigaltstack(&ss, NULL) != 0)
	{
		DBG_LOG("Setting up alternate signal stack failed.");
		exit(0);
	}  
	
	struct sigaction sig_action = {};
	memset(&sig_action, 0, sizeof(sig_action));
	sigemptyset(&sig_action.sa_mask);
	sig_action.sa_sigaction		= Signal_Handler;
	sig_action.sa_flags			= SA_SIGINFO;// | SA_ONSTACK;
	//if (sigaction(name, &sig_action, NULL) != 0) \
	*/
 
#define HANDLE_SIGNAL(name) \
	if (signal(name, Signal_Handler) != 0) \
	{ \
		DBG_LOG("Failed to setup signal handler for " #name); \
		/* exit(0); This really shouldn't result in a hard fault. */ \
	} \
	else \
	{ \
		DBG_LOG("Installed signal handler for: " #name); \
	} \

	HANDLE_SIGNAL(SIGABRT);
	HANDLE_SIGNAL(SIGFPE);
	HANDLE_SIGNAL(SIGILL);
	//HANDLE_SIGNAL(SIGINT);
	HANDLE_SIGNAL(SIGSEGV);
	//HANDLE_SIGNAL(SIGTERM);

#undef HANDLE_SIGNAL

#define HANDLE_SIGNAL(name) \
	if (signal(name, Signal_Termination_Handler) != 0) \
	{ \
		DBG_LOG("Failed to setup termination signal handler for " #name); \
		/* exit(0); This really shouldn't result in a hard fault. */ \
	} \
	else \
	{ \
		DBG_LOG("Installed termination signal handler for: " #name); \
	} \

	HANDLE_SIGNAL(SIGINT);
	HANDLE_SIGNAL(SIGTERM);
#undef HANDLE_SIGNAL
}

void macos_end()
{
	GameEngine::Get()->Stop();
}

int macos_main(int argc, char* argv[])
{	
	// Enable logging if requested.
	for (int i = 0; i < argc; i++)
	{
		if (stricmp(argv[i], "-log") == 0)
		{
			Platform_Enable_Log_File();
		}
	}

	// Before anything else we initialize memory allocations!
	if (!MemoryManager::Init())
	{
		DBG_LOG("Failed to initialize platform memory.");
		return 1;
	}
	
	// Initialize platform.
	DBG_LOG("Initialising platform singleton.");
	{
		Platform::Create();
	}
	
	// Get some global info.
	g_main_thread = pthread_self();
	g_executable_file_path = argv[0];

	MacOS_Thread::Setup_Main();

	// Print out debugging information.
	DBG_LOG("--------------------------------------------------------------------------------------");
#ifdef DEBUG_BUILD
	DBG_LOG(" XGE Debug              Version %s, Built %s/%s/%s %s:%s", EngineAutoVersion::FULLVERSION_STRING, EngineAutoVersion::DAY, EngineAutoVersion::MONTH, EngineAutoVersion::YEAR, EngineAutoVersion::HOUR, EngineAutoVersion::MINUTE);
#else
	DBG_LOG(" XGE Release            Version %s, Built %s/%s/%s %s:%s", EngineAutoVersion::FULLVERSION_STRING, EngineAutoVersion::DAY, EngineAutoVersion::MONTH, EngineAutoVersion::YEAR, EngineAutoVersion::HOUR, EngineAutoVersion::MINUTE);
#endif
	Print_Game_Version();
	DBG_LOG("--------------------------------------------------------------------------------------");
	DBG_LOG(" Copyright (C) 2013-2014 TwinDrills");
	DBG_LOG("--------------------------------------------------------------------------------------");

	// Install exception filter.
	// On non-steam builds we want to install an exception handler, steam uploads crash dumps for us though, so no need to do this.	
//#ifndef OPT_STEAM_PLATFORM
	DBG_LOG("Installing signal handlers.");
	Install_Signal_Handler();
//#endif

	// Instantiate factories we will be using. (I wish static instantiation for auto-registration worked
	//											over static library boundries ;_;)
	DBG_LOG("Instantiating factories.");
	MacOS_FileStreamFactory fileStreamFactory;
	PNGPixelmapFactory		pngFactory;
	FreeType_FontFactory	freeTypeFactory;
	
	// Set main thread affinity to the first core only.
//	DBG_LOG("Setting main thread affinity to core 0.");
//	Thread::Get_Current()->Set_Affinity(1 << 0);

	// Seed random.
	int seed = time(NULL);
	DBG_LOG("Seeding random to 0x%08x", seed);
	srand(seed);
	Random::Seed_Static(seed);

	// Engine variables that we need to setup.
	//GameRunner* runner;
	//GameEngine* engine;
	
	// Concatinate the command line into a beast.
	std::string command_line = "";

	// Eeeeeh, linux has no equivilent of GetCommandLine :(

	for (int i = 0; i < argc; i++)
	{
		command_line += StringHelper::Format("\"%s\" ", argv[i]);
		DBG_LOG("argv[%i] %s", i, argv[i]);
	}

	// Set working directory to executable directory, or if we are running as an app, to our top-level
	// directory (this is a shitty way of doing things, but allows us to keep one depot for data).
	Platform* plat = Platform::Get();

	std::string exe_path = argv[0];

	char exe_base_path[8096];
	uint32_t size = sizeof(exe_base_path);
	if (_NSGetExecutablePath(exe_base_path, &size) == 0)
	{
		DBG_LOG("_NSGetExecutablePath: %s", exe_base_path);
		exe_path = exe_base_path;
	}
	
	DBG_LOG("Executable Path: %s", exe_path.c_str());

	std::string exe_dir = Platform::Get()->Extract_Directory(exe_path);
	
	DBG_LOG("Executable Directory: %s", exe_dir.c_str());

	std::vector<std::string> segments;
	plat->Crack_Path(exe_dir.c_str(), segments);

	std::string working_dir = "";
	for (std::vector<std::string>::iterator iter = segments.begin(); iter != segments.end(); iter++)
	{
		std::string seg = *iter;

		if (seg.find(".app") != std::string::npos)
		{
			break;
		}

		working_dir += "/" + seg;
	}

	DBG_LOG("Setting working directory to: %s", working_dir.c_str());
	plat->Set_Working_Dir(working_dir.c_str());

	// Set the long jump varaible. We use this to bail out and continue
	// cleaning up if the unhandled exception filter is invoked.	
	DBG_LOG("Creating setjmp handle for error recovery.");
	int exitcode = setjmp(g_error_recovery_longjmp);
	if (exitcode == 0)
	{
		Game_Entry_Point(command_line.c_str());
		/*
		DBG_LOG("Creating new game instance.");
		runner = New_Game();
	
		DBG_LOG("Creating new engine instance.");
		engine = new GameEngine(runner, command_line.c_str());

		DBG_LOG("Running game engine.");
		engine->Run();
		*/
	}
	else
	{
		DBG_LOG("Recovered from unhandled exception. Beginning cleanup.");
	}

	// Clean everything up.
//	DBG_LOG("Disposing of engine.");
//	SAFE_DELETE(engine);

//	DBG_LOG("Disposing of game.");
//	SAFE_DELETE(runner);

	// All done!
	return 0;
}

#endif