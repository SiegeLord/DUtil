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

module dutil.Array;

import tango.stdc.stdlib;

struct SArray(T)
{
	alias Length length;
	
	this(size_t ini_length)
	{
		Resize(ini_length);
	}
	
	this(size_t ini_length, T ini_val)
	{
		Resize(ini_length, ini_val);
	}
	
	~this()
	{
		Length = 0;
		Capacity = 0;
	}
	
	void Resize(size_t new_length)
	{
		if(new_length > Capacity)
		{
			Capacity = new_length;
		}
		LengthVal = new_length;
	}
	
	void Resize(size_t new_length, T ini_val)
	{
		auto old_length = Length;
		Resize(new_length);
		if(new_length > old_length)
		Data[old_length..new_length] = ini_val;
	}
	
	@property
	void Length(size_t new_length)
	{
		Resize(new_length, T.init);
	}
	
	@property
	size_t Length() const
	{
		return LengthVal;
	}
	
	@property
	void Capacity(size_t new_capacity)
	{
		assert(new_capacity >= Length);
		
		if(new_capacity > Capacity)
		{
			Data = cast(T*)realloc(Data, new_capacity * T.sizeof);
			assert(Data !is null);
		}
		
		CapacityVal = new_capacity;
	}

	@property
	size_t Capacity() const
	{
		return CapacityVal;
	}

	inout(T)[] opSlice() inout
	{
		return Data[0..Length];
	}

	inout(T)[] opSlice(size_t start, size_t end) inout
	{
		assert(end < Length);
		assert(start <= end);
		return Data[start..end];
	}

	T opSliceAssign(size_t start, size_t end, T val)
	{
		assert(end < Length);
		assert(start <= end);
		
		Data[start..end] = val;
		return val;
	}

	T opSliceAssign(T val)
	{
		Data[0..Length] = val;
		return val;
	}

	ref inout(T) opIndex(size_t idx) inout
	{
		assert(idx < Length);
		return Data[idx];
	}

	void opCatAssign(T val)
	{
		if(Length >= Capacity)
			Capacity = 3 * Length / 2 + 1;
		
		Length = Length + 1;
		Data[Length - 1] = val;
	}
	
	T* Data;
protected:
	size_t LengthVal;
	size_t CapacityVal;
}

unittest
{
	auto arr1 = SArray!(int)();
	assert(arr1.length == 0);
	arr1.length = 1;
	assert(arr1.length == 1);
	assert(arr1.Capacity == 1);
	arr1.length = 2;
	arr1[0] = 5;
	arr1[1] = 1;
	assert(arr1[0] == 5);
	assert(arr1[1] == 1);
	arr1[] = 5;
	assert(arr1[0] == 5);
	assert(arr1[1] == 5);
	arr1 ~= 6;
	assert(arr1[0] == 5);
	assert(arr1[1] == 5);
	assert(arr1[2] == 6);
}
