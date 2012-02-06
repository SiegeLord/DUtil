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

/**
 * D1 only.
 * 
 * Some general utility functions.
 */

module dutil.General;

import tango.sys.Process;
import tango.io.stream.Text;
import tango.io.Stdout;
import tango.stdc.stringz;

private char[] c_str_buf;
char* c_str(const(char)[] dstr)
{
	if(dstr.length >= c_str_buf.length)
		c_str_buf.length = dstr.length + 1;
	return toStringz(dstr, c_str_buf);
}

void println(T...)(in char[] fmt, T args)
{
	Stdout.formatln(fmt, args);
}

T[] deep_dup(T)(T[] arr)
{
	T[] ret;
	ret.length = arr.length;
	foreach(ii, el; arr)
		ret[ii] = el.dup;
	return ret;
}

range_fruct!(T) range(T)(T end)
{
	range_fruct!(T) ret;
	ret.end = end;
	return ret;
}

range_fruct!(T) range(T)(T start, T end)
{
	range_fruct!(T) ret;
	ret.start = start;
	ret.end = end;
	return ret;
}

range_fruct!(T) range(T)(T start, T end, T step)
{
	range_fruct!(T) ret;
	ret.start = start;
	ret.end = end;
	ret.step = step;
	return ret;
}

struct range_fruct(T)
{	
	int opApply(scope int delegate(ref T ii) dg)
	{
		for(T ii = start; ii < end; ii += step)
		{
			if(int ret = dg(ii))
				return ret;
		}
		return 0;
	}
	
	T start = 0;
	T end = 0;
	T step = 1;
}

const(char)[] GetGitRevisionHash()
{
	const(char)[] ret;
	try
	{
		auto git = new Process(true, "git rev-parse HEAD");
		git.execute();
		auto input = new TextInput(git.stdout);
		input.readln(ret);
		git.wait();
	}
	catch(Exception e)
	{
		Stdout(e).nl;
	}
	return ret;
}

const(char)[] Prop(const(char)[] type, const(char)[] name, const(char)[] get_attr = "", const(char)[] set_attr = "")()
{
	return
	"@property " ~ get_attr ~ "
	" ~ type ~ " " ~ name ~ "()
	{
		return " ~ name ~ "Val;
	}
	
	@property " ~ set_attr ~ "
	void " ~ name ~ "(" ~ type ~ " val)
	{
		" ~ name ~ "Val = val;
	}";
}
