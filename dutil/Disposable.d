/*
Copyright (c) 2010-2011 Pavel Sountsov

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

   1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.

   2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.

   3. This notice may not be removed or altered from any source
   distribution.
*/

module dutil.Disposable;

version(DebugDisposable) import tango.stdc.stdio;

/**
 * A simple class that formalizes the non-managed resource management. The advantage of using this
 * is that with version DebugDisposable defined, it will track whether all the resources were disposed of
 */
class CDisposable
{
	this()
	{
		version(DebugDisposable)
		{
			InstanceCounts[this.classinfo.name]++;
		}
		
		IsDisposed = false;
	}
	
	void Dispose()
	{
		version(DebugDisposable)
		{
			if(!IsDisposed)
			{
				InstanceCounts[this.classinfo.name]--;
			}
		}

		IsDisposed = true;
	}
	
protected:
	bool IsDisposed = false;
}

version(DebugDisposable)
{
	size_t InstanceCounts[char[]];

	static ~this()
	{
		printf("Disposable classes instance counts:\n");
		bool any = false;
		foreach(name, num; InstanceCounts)
		{
			if(num)
			{
				printf("%s: \033[1;31m%d\033[0m\n", (name ~ "\0").ptr, num);
				any = true;
			}
		}
		if(!any)
			printf("No leaked instances!\n");
	}
}
