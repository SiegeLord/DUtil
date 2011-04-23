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
 * A expression template based vector struct, useful for writting succinct and at the same fast math expressions.
 * Is somewhat slower than naive loops, but should be pretty good for most tasks.
 * 
 * Due to limitation of D1 templates, all non-commutative combination of numbers and vectors must have the numbers on the left hand 
 * side. This doesn't happen in D2, so when I switch to D2, it won't be an issue.
 * 
 * ---
 * VectorD vec;
 * // OK
 * 1 - vec;
 * -1 + vec;
 * vec + (-1);
 * // Not OK
 * vec - 1;
 * vec / 2;
 * ---
 */

module VectorMath;

import math = tango.math.Math;

private template ArrayType(T)
{
	const ArrayType = is(typeof(T[0])) && is(typeof(T.length));
}

private template UnaryOp(char[] op, char[] fn_name)
{
	const char[] UnaryOp = 
	`
	BinaryExpressionType!("*0+` ~ op ~ `", T, int, typeof(*this)) ` ~ fn_name ~ `(Dummy = void)()
	{
		return BinaryExpressionType!("*0+` ~ op ~ `", T, int, typeof(*this))(0, *this);
	}
	`;
}

private template BinaryOp(char[] op, char[] fn_name)
{
	const char[] BinaryOp = 
	`
	BinaryExpressionType!("` ~ op ~ `", T, typeof(*this), ValT) ` ~ fn_name ~ `(ValT)(ValT other)
	{
		return BinaryExpressionType!("` ~ op ~ `", T, typeof(*this), ValT)(*this, other);
	}
	`;
}

private template BinaryOpR(char[] op, char[] fn_name)
{
	const char[] BinaryOpR = 
	`
	BinaryExpressionType!("` ~ op ~ `", T, ValT, typeof(*this)) ` ~ fn_name ~ `(ValT)(ValT other)
	{
		return BinaryExpressionType!("` ~ op ~ `", T, ValT, typeof(*this))(other, *this);
	}
	`;
}

alias Vector!(double) VectorD;
alias Vector!(float) VectorF;

private template ExpressionOps()
{
	mixin(BinaryOp!("+", "opAdd"));
	//mixin(BinaryOp!("-", "opSub"));
	mixin(BinaryOp!("*", "opMul"));
	//mixin(BinaryOp!("/", "opDiv"));
	
	mixin(BinaryOpR!("-", "opSub_r"));
	mixin(BinaryOpR!("/", "opDiv_r"));
	
	mixin(UnaryOp!("-", "opNeg"));
	
	Vector!(T) dup()
	{
		auto ret = Vector!(T)(length);
		ret = *this;
		
		return ret;
	}
}

/* Workabout for a bug in recursive template instantiation detection */
private template BinaryExpressionType(char[] op, T, LHS_t, RHS_t)
{
	typedef BinaryExpression!(op, T, LHS_t, RHS_t) BinaryExpressionType;
}

struct BinaryExpression(char[] op, T, LHS_t, RHS_t)
{
	T opIndex(size_t idx)
	{
		const lhs_idx = ArrayType!(LHS_t);
		const rhs_idx = ArrayType!(RHS_t);
		
		static if(lhs_idx && rhs_idx)
		{
			mixin("return LHS[idx] " ~ op ~ " (RHS[idx]);");
		}
		else static if(lhs_idx)
		{
			mixin("return LHS[idx] " ~ op ~ " (RHS);");
		}
		else static if(rhs_idx)
		{
			mixin("return LHS " ~ op ~ " (RHS[idx]);");
		}
		else
		{
			mixin("return LHS " ~ op ~ " (RHS);");
		}
	}
	
	mixin ExpressionOps;
	
	size_t length()
	{
		const lhs_idx = ArrayType!(LHS_t);
		const rhs_idx = ArrayType!(RHS_t);
		
		static if(lhs_idx)
		{
			mixin("return LHS.length;");
		}
		else static if(rhs_idx)
		{
			mixin("return RHS.length;");
		}
		else
		{
			mixin("return 1;");
		}
	}
	
	LHS_t LHS;
	RHS_t RHS;
}

struct PowExpression(T, RHS_t)
{
	T opIndex(size_t idx)
	{
		static if(ArrayType!(RHS_t))
		{
			mixin("return math.pow(RHS[idx], Power);");
		}
		else
		{
			mixin("return math.pow(RHS, Power);");
		}
	}
	
	mixin ExpressionOps;
	
	size_t length()
	{
		static if(ArrayType!(RHS_t))
		{
			mixin("return RHS.length;");
		}
		else
		{
			mixin("return 1;");
		}
	}
	
	RHS_t RHS;
	T Power;
}

struct Vector(T)
{
	static Vector opCall(size_t len = 0, T init = T.init)
	{
		Vector ret;
		ret.Data.length = len;
		ret.Data[] = init;
		
		return ret;
	}
	
	static Vector opCall(T[] arr)
	{
		Vector ret;
		ret.Data = arr;
		
		return ret;
	}
	
	mixin ExpressionOps;
	
	T[] opSlice()
	{
		return Data;
	}
	
	T opIndex(size_t idx)
	{
		return Data[idx];
	}
	
	T opIndexAssign(T val, size_t idx)
	{
		return Data[idx] = val;
	}
	
	Vector opAssign(ValT)(ValT other)
	{
		static if(ArrayType!(ValT))
		{
			assert(length == other.length, "Incompatible vector lengths.");
			foreach(idx, ref val; Data)
			{
				val = other[idx];
			}
		}
		else
		{
			Data[] = other;
		}
		
		return *this;
	}
	
	size_t length()
	{
		return Data.length;
	}
	
	void length(size_t len)
	{
		Data.length = len;
	}
	
	T[] Data;
}

private template Func(char[] op, char[] fn_name)
{
	const char[] Func = 
	`
	BinaryExpressionType!("*0+` ~ op ~ `", real, int, RHS_t) ` ~ fn_name ~ `(RHS_t)(RHS_t rhs)
	{
		return BinaryExpressionType!("*0+` ~ op ~ `", real, int, RHS_t)(0, rhs);
	}
	`;
}

mixin(Func!("math.exp", "exp"));
mixin(Func!("math.abs", "abs"));
mixin(Func!("math.sqrt", "sqrt"));

PowExpression!(real, RHS_t) pow(RHS_t)(RHS_t rhs, real power)
{
	return PowExpression!(real, RHS_t)(rhs, power);
}

version(UnitTest)
{

import tango.io.Stdout;
	
unittest
{
	a = 1 - a;
	Stdout(a[]).nl;
	a = a - a;
	Stdout(a[]).nl;
	a = (-1) + a;
	Stdout(a[]).nl;
	a = 5;
	a = 1 / (a + a);
	Stdout(a[]).nl;
	a = -a;
	Stdout(a[]).nl;
	a = 1 / (1 + exp(-a));
	Stdout(a[]).nl;
	a[1] = -a[1];
	Stdout(a[]).nl;
	a = abs(a);
	Stdout(a[]).nl;
	a = 2;
	auto b = (pow(a, 2)).dup;
	Stdout(b[]).nl;
	Stdout(a[]).nl;
}

}
