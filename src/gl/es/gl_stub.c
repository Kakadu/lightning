/*
 * GLCaml - Objective Caml interface for OpenGL 1.1, 1.2, 1.3, 1.4, 1.5, 2.0 and 2.1
 * plus extensions: 
 *
 * Copyright (C) 2007, 2008 Elliott OTI
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided 
 * that the following conditions are met:
 *  - Redistributions of source code must retain the above copyright notice, this list of conditions 
 *    and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
 *    and the following disclaimer in the documentation and/or other materials provided with the distribution.
 *  - The name Elliott Oti may not be used to endorse or promote products derived from this software 
 *    without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * 'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <stdio.h>
#include <string.h> 
#include <OpenGLES/ES1/gl.h>

 
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/callback.h>
#include <caml/bigarray.h>


#ifdef _WIN32
#include <windows.h>

static HMODULE lib=NULL;

static void init_lib()
{
	if(lib)return;
	lib = LoadLibrary("opengl32.dll");
	if(lib == NULL) failwith("error loading opengl32.dll");
}

static void *get_proc_address(char *fname)
{
	return GetProcAddress(lib, fname);
}

#endif

#ifdef __unix__
#ifndef APIENTRY
#define APIENTRY
#endif
#include <dlfcn.h>
#include <stdio.h>

static void* lib=NULL;

static void init_lib()
{
	if(lib)return;
	lib = dlopen("libGL.so.1",RTLD_LAZY);
	if(lib == NULL) failwith("error loading libGL.so.1");
}

static void *get_proc_address(char *fname)
{
	return dlsym(lib, fname);
}

#endif

#if defined(__APPLE__) && defined(__GNUC__)
#ifndef APIENTRY
#define APIENTRY
#endif
#include <dlfcn.h>
#include <stdio.h>

static void* lib=NULL;

static void init_lib()
{
	if(lib)return;
	lib = dlopen("libGL.dylib",RTLD_LAZY);
	if(lib == NULL) failwith("error loading libGL.dylib");
}

static void *get_proc_address(char *fname)
{
	return dlsym(lib, fname);
}
#endif

value unsafe_coercion(value v)
{
        CAMLparam1(v);
        CAMLreturn(v);
}


#define DECLARE_FUNCTION(func, args, ret)						\
typedef ret APIENTRY (*pstub_##func)args;						\
static pstub_##func stub_##func = NULL;							\
static int loaded_##func = 0;



#define LOAD_FUNCTION(func) 									\
	if(!loaded_##func)											\
	{															\
		init_lib ();											\
		stub_##func = (pstub_##func)get_proc_address(#func);	\
		if(stub_##func)											\
		{														\
			loaded_##func = 1;									\
		}														\
		else													\
		{														\
			char fn[256], buf[300];								\
			strncpy(fn, #func, 255);							\
			sprintf(buf, "Unable to load %s", fn);			\
			caml_failwith(buf);									\
		}														\
	}



value glstub_glActiveTexture(value v0)
{
	CAMLparam1(v0);
	GLenum lv0 = Int_val(v0);
	glActiveTexture(lv0);
	CAMLreturn(Val_unit);
}

value glstub_glAlphaFunc(value v0, value v1)
{
	CAMLparam2(v0, v1);
	GLenum lv0 = Int_val(v0);
	GLclampf lv1 = Double_val(v1);
	glAlphaFunc(lv0, lv1);
	CAMLreturn(Val_unit);
}

value glstub_glBindBuffer(value v0, value v1)
{
	CAMLparam2(v0, v1);
	GLenum lv0 = Int_val(v0);
	GLuint lv1 = Int_val(v1);
	glBindBuffer(lv0, lv1);
	CAMLreturn(Val_unit);
}

value glstub_glBindTexture(value v0, value v1)
{
	CAMLparam2(v0, v1);
	GLenum lv0 = Int_val(v0);
	GLuint lv1 = Int_val(v1);
	glBindTexture(lv0, lv1);
	CAMLreturn(Val_unit);
}

value glstub_glBlendFunc(value v0, value v1)
{
	CAMLparam2(v0, v1);
	GLenum lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	glBlendFunc(lv0, lv1);
	CAMLreturn(Val_unit);
}

value glstub_glBufferData(value v0, value v1, value v2, value v3)
{
	CAMLparam4(v0, v1, v2, v3);
	GLenum lv0 = Int_val(v0);
	GLsizeiptr lv1 = Int_val(v1);
	GLvoid* lv2 = (GLvoid *)(Is_long(v2) ? (void*)Long_val(v2) : ((Tag_val(v2) == String_tag)? (String_val(v2)) : (Data_bigarray_val(v2))));
	GLenum lv3 = Int_val(v3);
	glBufferData(lv0, lv1, lv2, lv3);
	CAMLreturn(Val_unit);
}

value glstub_glBufferSubData(value v0, value v1, value v2, value v3)
{
	CAMLparam4(v0, v1, v2, v3);
	GLenum lv0 = Int_val(v0);
	GLintptr lv1 = Int_val(v1);
	GLsizeiptr lv2 = Int_val(v2);
	GLvoid* lv3 = (GLvoid *)(Is_long(v3) ? (void*)Long_val(v3) : ((Tag_val(v3) == String_tag)? (String_val(v3)) : (Data_bigarray_val(v3))));
	glBufferSubData(lv0, lv1, lv2, lv3);
	CAMLreturn(Val_unit);
}

value glstub_glClear(value v0)
{
	CAMLparam1(v0);
	GLbitfield lv0 = Int_val(v0);
	glClear(lv0);
	CAMLreturn(Val_unit);
}

value glstub_glClearColor(value v0, value v1, value v2, value v3)
{
	CAMLparam4(v0, v1, v2, v3);
	GLclampf lv0 = Double_val(v0);
	GLclampf lv1 = Double_val(v1);
	GLclampf lv2 = Double_val(v2);
	GLclampf lv3 = Double_val(v3);
	glClearColor(lv0, lv1, lv2, lv3);
	CAMLreturn(Val_unit);
}

value glstub_glClearDepthf(value v0)
{
	CAMLparam1(v0);
	GLclampf lv0 = Double_val(v0);
	glClearDepthf(lv0);
	CAMLreturn(Val_unit);
}

value glstub_glClearStencil(value v0)
{
	CAMLparam1(v0);
	GLint lv0 = Int_val(v0);
	glClearStencil(lv0);
	CAMLreturn(Val_unit);
}

value glstub_glClientActiveTexture(value v0)
{
	CAMLparam1(v0);
	GLenum lv0 = Int_val(v0);
	glClientActiveTexture(lv0);
	CAMLreturn(Val_unit);
}

value glstub_glClipPlanef(value v0, value v1)
{
	CAMLparam2(v0, v1);
	GLenum lv0 = Int_val(v0);
	GLfloat* lv1 = Data_bigarray_val(v1);
	glClipPlanef(lv0, lv1);
	CAMLreturn(Val_unit);
}

value glstub_glColor4f(value v0, value v1, value v2, value v3)
{
	CAMLparam4(v0, v1, v2, v3);
	GLfloat lv0 = Double_val(v0);
	GLfloat lv1 = Double_val(v1);
	GLfloat lv2 = Double_val(v2);
	GLfloat lv3 = Double_val(v3);
	glColor4f(lv0, lv1, lv2, lv3);
	CAMLreturn(Val_unit);
}

value glstub_glColor4ub(value v0, value v1, value v2, value v3)
{
	CAMLparam4(v0, v1, v2, v3);
	GLubyte lv0 = Int_val(v0);
	GLubyte lv1 = Int_val(v1);
	GLubyte lv2 = Int_val(v2);
	GLubyte lv3 = Int_val(v3);
	glColor4ub(lv0, lv1, lv2, lv3);
	CAMLreturn(Val_unit);
}

value glstub_glColorMask(value v0, value v1, value v2, value v3)
{
	CAMLparam4(v0, v1, v2, v3);
	GLboolean lv0 = Bool_val(v0);
	GLboolean lv1 = Bool_val(v1);
	GLboolean lv2 = Bool_val(v2);
	GLboolean lv3 = Bool_val(v3);
	glColorMask(lv0, lv1, lv2, lv3);
	CAMLreturn(Val_unit);
}

value glstub_glColorPointer(value v0, value v1, value v2, value v3)
{
	CAMLparam4(v0, v1, v2, v3);
	GLint lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	GLsizei lv2 = Int_val(v2);
	GLvoid* lv3 = (GLvoid *)(Is_long(v3) ? (void*)Long_val(v3) : ((Tag_val(v3) == String_tag)? (String_val(v3)) : (Data_bigarray_val(v3))));
	glColorPointer(lv0, lv1, lv2, lv3);
	CAMLreturn(Val_unit);
}

value glstub_glCompressedTexImage2D(value v0, value v1, value v2, value v3, value v4, value v5, value v6, value v7)
{
	CAMLparam5(v0, v1, v2, v3, v4);
	CAMLxparam3(v5, v6, v7);
	GLenum lv0 = Int_val(v0);
	GLint lv1 = Int_val(v1);
	GLenum lv2 = Int_val(v2);
	GLsizei lv3 = Int_val(v3);
	GLsizei lv4 = Int_val(v4);
	GLint lv5 = Int_val(v5);
	GLsizei lv6 = Int_val(v6);
	GLvoid* lv7 = (GLvoid *)(Is_long(v7) ? (void*)Long_val(v7) : ((Tag_val(v7) == String_tag)? (String_val(v7)) : (Data_bigarray_val(v7))));
	glCompressedTexImage2D(lv0, lv1, lv2, lv3, lv4, lv5, lv6, lv7);
	CAMLreturn(Val_unit);
}

value glstub_glCompressedTexImage2D_byte(value * argv, int n)
{
	return glstub_glCompressedTexImage2D(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7]);
}

value glstub_glCompressedTexSubImage2D(value v0, value v1, value v2, value v3, value v4, value v5, value v6, value v7, value v8)
{
	CAMLparam5(v0, v1, v2, v3, v4);
	CAMLxparam4(v5, v6, v7, v8);
	GLenum lv0 = Int_val(v0);
	GLint lv1 = Int_val(v1);
	GLint lv2 = Int_val(v2);
	GLint lv3 = Int_val(v3);
	GLsizei lv4 = Int_val(v4);
	GLsizei lv5 = Int_val(v5);
	GLenum lv6 = Int_val(v6);
	GLsizei lv7 = Int_val(v7);
	GLvoid* lv8 = (GLvoid *)(Is_long(v8) ? (void*)Long_val(v8) : ((Tag_val(v8) == String_tag)? (String_val(v8)) : (Data_bigarray_val(v8))));
	glCompressedTexSubImage2D(lv0, lv1, lv2, lv3, lv4, lv5, lv6, lv7, lv8);
	CAMLreturn(Val_unit);
}

value glstub_glCompressedTexSubImage2D_byte(value * argv, int n)
{
	return glstub_glCompressedTexSubImage2D(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8]);
}

value glstub_glCopyTexImage2D(value v0, value v1, value v2, value v3, value v4, value v5, value v6, value v7)
{
	CAMLparam5(v0, v1, v2, v3, v4);
	CAMLxparam3(v5, v6, v7);
	GLenum lv0 = Int_val(v0);
	GLint lv1 = Int_val(v1);
	GLenum lv2 = Int_val(v2);
	GLint lv3 = Int_val(v3);
	GLint lv4 = Int_val(v4);
	GLsizei lv5 = Int_val(v5);
	GLsizei lv6 = Int_val(v6);
	GLint lv7 = Int_val(v7);
	glCopyTexImage2D(lv0, lv1, lv2, lv3, lv4, lv5, lv6, lv7);
	CAMLreturn(Val_unit);
}

value glstub_glCopyTexImage2D_byte(value * argv, int n)
{
	return glstub_glCopyTexImage2D(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7]);
}

value glstub_glCopyTexSubImage2D(value v0, value v1, value v2, value v3, value v4, value v5, value v6, value v7)
{
	CAMLparam5(v0, v1, v2, v3, v4);
	CAMLxparam3(v5, v6, v7);
	GLenum lv0 = Int_val(v0);
	GLint lv1 = Int_val(v1);
	GLint lv2 = Int_val(v2);
	GLint lv3 = Int_val(v3);
	GLint lv4 = Int_val(v4);
	GLint lv5 = Int_val(v5);
	GLsizei lv6 = Int_val(v6);
	GLsizei lv7 = Int_val(v7);
	glCopyTexSubImage2D(lv0, lv1, lv2, lv3, lv4, lv5, lv6, lv7);
	CAMLreturn(Val_unit);
}

value glstub_glCopyTexSubImage2D_byte(value * argv, int n)
{
	return glstub_glCopyTexSubImage2D(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7]);
}

value glstub_glCullFace(value v0)
{
	CAMLparam1(v0);
	GLenum lv0 = Int_val(v0);
	glCullFace(lv0);
	CAMLreturn(Val_unit);
}

value glstub_glCurrentPaletteMatrixOES(value v0)
{
	CAMLparam1(v0);
	GLuint lv0 = Int_val(v0);
	glCurrentPaletteMatrixOES(lv0);
	CAMLreturn(Val_unit);
}

value glstub_glDeleteBuffers(value v0, value v1)
{
	CAMLparam2(v0, v1);
	GLsizei lv0 = Int_val(v0);
	GLuint* lv1 = Data_bigarray_val(v1);
	glDeleteBuffers(lv0, lv1);
	CAMLreturn(Val_unit);
}

value glstub_glDeleteTextures(value v0, value v1)
{
	CAMLparam2(v0, v1);
	GLsizei lv0 = Int_val(v0);
	GLuint* lv1 = Data_bigarray_val(v1);
	glDeleteTextures(lv0, lv1);
	CAMLreturn(Val_unit);
}

value glstub_glDepthFunc(value v0)
{
	CAMLparam1(v0);
	GLenum lv0 = Int_val(v0);
	glDepthFunc(lv0);
	CAMLreturn(Val_unit);
}

value glstub_glDepthMask(value v0)
{
	CAMLparam1(v0);
	GLboolean lv0 = Bool_val(v0);
	glDepthMask(lv0);
	CAMLreturn(Val_unit);
}

value glstub_glDepthRangef(value v0, value v1)
{
	CAMLparam2(v0, v1);
	GLclampf lv0 = Double_val(v0);
	GLclampf lv1 = Double_val(v1);
	glDepthRangef(lv0, lv1);
	CAMLreturn(Val_unit);
}

value glstub_glDisable(value v0)
{
	CAMLparam1(v0);
	GLenum lv0 = Int_val(v0);
	glDisable(lv0);
	CAMLreturn(Val_unit);
}

value glstub_glDisableClientState(value v0)
{
	CAMLparam1(v0);
	GLenum lv0 = Int_val(v0);
	glDisableClientState(lv0);
	CAMLreturn(Val_unit);
}

value glstub_glDrawArrays(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLenum lv0 = Int_val(v0);
	GLint lv1 = Int_val(v1);
	GLsizei lv2 = Int_val(v2);
	glDrawArrays(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glDrawElements(value v0, value v1, value v2, value v3)
{
	CAMLparam4(v0, v1, v2, v3);
	GLenum lv0 = Int_val(v0);
	GLsizei lv1 = Int_val(v1);
	GLenum lv2 = Int_val(v2);
	GLvoid* lv3 = (GLvoid *)(Is_long(v3) ? (void*)Long_val(v3) : ((Tag_val(v3) == String_tag)? (String_val(v3)) : (Data_bigarray_val(v3))));
	glDrawElements(lv0, lv1, lv2, lv3);
	CAMLreturn(Val_unit);
}

value glstub_glDrawTexfOES(value v0, value v1, value v2, value v3, value v4)
{
	CAMLparam5(v0, v1, v2, v3, v4);
	GLfloat lv0 = Double_val(v0);
	GLfloat lv1 = Double_val(v1);
	GLfloat lv2 = Double_val(v2);
	GLfloat lv3 = Double_val(v3);
	GLfloat lv4 = Double_val(v4);
	glDrawTexfOES(lv0, lv1, lv2, lv3, lv4);
	CAMLreturn(Val_unit);
}

value glstub_glDrawTexfvOES(value v0)
{
	CAMLparam1(v0);
	GLfloat* lv0 = Data_bigarray_val(v0);
	glDrawTexfvOES(lv0);
	CAMLreturn(Val_unit);
}

value glstub_glDrawTexiOES(value v0, value v1, value v2, value v3, value v4)
{
	CAMLparam5(v0, v1, v2, v3, v4);
	GLint lv0 = Int_val(v0);
	GLint lv1 = Int_val(v1);
	GLint lv2 = Int_val(v2);
	GLint lv3 = Int_val(v3);
	GLint lv4 = Int_val(v4);
	glDrawTexiOES(lv0, lv1, lv2, lv3, lv4);
	CAMLreturn(Val_unit);
}

value glstub_glDrawTexivOES(value v0)
{
	CAMLparam1(v0);
	GLint* lv0 = Data_bigarray_val(v0);
	glDrawTexivOES(lv0);
	CAMLreturn(Val_unit);
}

value glstub_glDrawTexsOES(value v0, value v1, value v2, value v3, value v4)
{
	CAMLparam5(v0, v1, v2, v3, v4);
	GLshort lv0 = Int_val(v0);
	GLshort lv1 = Int_val(v1);
	GLshort lv2 = Int_val(v2);
	GLshort lv3 = Int_val(v3);
	GLshort lv4 = Int_val(v4);
	glDrawTexsOES(lv0, lv1, lv2, lv3, lv4);
	CAMLreturn(Val_unit);
}

value glstub_glDrawTexsvOES(value v0)
{
	CAMLparam1(v0);
	GLshort* lv0 = Data_bigarray_val(v0);
	glDrawTexsvOES(lv0);
	CAMLreturn(Val_unit);
}

value glstub_glEnable(value v0)
{
	CAMLparam1(v0);
	GLenum lv0 = Int_val(v0);
	glEnable(lv0);
	CAMLreturn(Val_unit);
}

value glstub_glEnableClientState(value v0)
{
	CAMLparam1(v0);
	GLenum lv0 = Int_val(v0);
	glEnableClientState(lv0);
	CAMLreturn(Val_unit);
}

value glstub_glFinish(value v0)
{
	CAMLparam1(v0);
	glFinish();
	CAMLreturn(Val_unit);
}

value glstub_glFlush(value v0)
{
	CAMLparam1(v0);
	glFlush();
	CAMLreturn(Val_unit);
}

value glstub_glFogf(value v0, value v1)
{
	CAMLparam2(v0, v1);
	GLenum lv0 = Int_val(v0);
	GLfloat lv1 = Double_val(v1);
	glFogf(lv0, lv1);
	CAMLreturn(Val_unit);
}

value glstub_glFogfv(value v0, value v1)
{
	CAMLparam2(v0, v1);
	GLenum lv0 = Int_val(v0);
	GLfloat* lv1 = Data_bigarray_val(v1);
	glFogfv(lv0, lv1);
	CAMLreturn(Val_unit);
}

value glstub_glFrontFace(value v0)
{
	CAMLparam1(v0);
	GLenum lv0 = Int_val(v0);
	glFrontFace(lv0);
	CAMLreturn(Val_unit);
}

value glstub_glFrustumf(value v0, value v1, value v2, value v3, value v4, value v5)
{
	CAMLparam5(v0, v1, v2, v3, v4);
	CAMLxparam1(v5);
	GLfloat lv0 = Double_val(v0);
	GLfloat lv1 = Double_val(v1);
	GLfloat lv2 = Double_val(v2);
	GLfloat lv3 = Double_val(v3);
	GLfloat lv4 = Double_val(v4);
	GLfloat lv5 = Double_val(v5);
	glFrustumf(lv0, lv1, lv2, lv3, lv4, lv5);
	CAMLreturn(Val_unit);
}

value glstub_glFrustumf_byte(value * argv, int n)
{
	return glstub_glFrustumf(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
}

value glstub_glGenBuffers(value v0, value v1)
{
	CAMLparam2(v0, v1);
	GLsizei lv0 = Int_val(v0);
	GLuint* lv1 = Data_bigarray_val(v1);
	glGenBuffers(lv0, lv1);
	CAMLreturn(Val_unit);
}

value glstub_glGenTextures(value v0, value v1)
{
	CAMLparam2(v0, v1);
	GLsizei lv0 = Int_val(v0);
	GLuint* lv1 = Data_bigarray_val(v1);
	glGenTextures(lv0, lv1);
	CAMLreturn(Val_unit);
}

value glstub_glGetBooleanv(value v0, value v1)
{
	CAMLparam2(v0, v1);
	GLenum lv0 = Int_val(v0);
	GLboolean* lv1 = Data_bigarray_val(v1);
	glGetBooleanv(lv0, lv1);
	CAMLreturn(Val_unit);
}

value glstub_glGetBufferParameteriv(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLenum lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	GLint* lv2 = Data_bigarray_val(v2);
	glGetBufferParameteriv(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glGetClipPlanef(value v0, value v1)
{
	CAMLparam2(v0, v1);
	GLenum lv0 = Int_val(v0);
	GLfloat* lv1 = Data_bigarray_val(v1);
	glGetClipPlanef(lv0, lv1);
	CAMLreturn(Val_unit);
}

value glstub_glGetError(value v0)
{
	CAMLparam1(v0);
	CAMLlocal1(result);
	GLenum ret;
	ret = glGetError();
	result = Val_int(ret);
	CAMLreturn(result);
}

value glstub_glGetFloatv(value v0, value v1)
{
	CAMLparam2(v0, v1);
	GLenum lv0 = Int_val(v0);
	GLfloat* lv1 = Data_bigarray_val(v1);
	glGetFloatv(lv0, lv1);
	CAMLreturn(Val_unit);
}

value glstub_glGetIntegerv(value v0, value v1)
{
	CAMLparam2(v0, v1);
	GLenum lv0 = Int_val(v0);
	GLint* lv1 = Data_bigarray_val(v1);
	glGetIntegerv(lv0, lv1);
	CAMLreturn(Val_unit);
}

value glstub_glGetLightfv(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLenum lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	GLfloat* lv2 = Data_bigarray_val(v2);
	glGetLightfv(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glGetMaterialfv(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLenum lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	GLfloat* lv2 = Data_bigarray_val(v2);
	glGetMaterialfv(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glGetTexEnvfv(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLenum lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	GLfloat* lv2 = Data_bigarray_val(v2);
	glGetTexEnvfv(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glGetTexEnviv(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLenum lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	GLint* lv2 = Data_bigarray_val(v2);
	glGetTexEnviv(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glGetTexParameterfv(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLenum lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	GLfloat* lv2 = Data_bigarray_val(v2);
	glGetTexParameterfv(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glGetTexParameteriv(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLenum lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	GLint* lv2 = Data_bigarray_val(v2);
	glGetTexParameteriv(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glHint(value v0, value v1)
{
	CAMLparam2(v0, v1);
	GLenum lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	glHint(lv0, lv1);
	CAMLreturn(Val_unit);
}

value glstub_glIsBuffer(value v0)
{
	CAMLparam1(v0);
	CAMLlocal1(result);
	GLuint lv0 = Int_val(v0);
	GLboolean ret;
	ret = glIsBuffer(lv0);
	result = Val_bool(ret);
	CAMLreturn(result);
}

value glstub_glIsEnabled(value v0)
{
	CAMLparam1(v0);
	CAMLlocal1(result);
	GLenum lv0 = Int_val(v0);
	GLboolean ret;
	ret = glIsEnabled(lv0);
	result = Val_bool(ret);
	CAMLreturn(result);
}

value glstub_glIsTexture(value v0)
{
	CAMLparam1(v0);
	CAMLlocal1(result);
	GLuint lv0 = Int_val(v0);
	GLboolean ret;
	ret = glIsTexture(lv0);
	result = Val_bool(ret);
	CAMLreturn(result);
}

value glstub_glLightModelf(value v0, value v1)
{
	CAMLparam2(v0, v1);
	GLenum lv0 = Int_val(v0);
	GLfloat lv1 = Double_val(v1);
	glLightModelf(lv0, lv1);
	CAMLreturn(Val_unit);
}

value glstub_glLightModelfv(value v0, value v1)
{
	CAMLparam2(v0, v1);
	GLenum lv0 = Int_val(v0);
	GLfloat* lv1 = Data_bigarray_val(v1);
	glLightModelfv(lv0, lv1);
	CAMLreturn(Val_unit);
}

value glstub_glLightf(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLenum lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	GLfloat lv2 = Double_val(v2);
	glLightf(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glLightfv(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLenum lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	GLfloat* lv2 = Data_bigarray_val(v2);
	glLightfv(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glLineWidth(value v0)
{
	CAMLparam1(v0);
	GLfloat lv0 = Double_val(v0);
	glLineWidth(lv0);
	CAMLreturn(Val_unit);
}

value glstub_glLoadIdentity(value v0)
{
	CAMLparam1(v0);
	glLoadIdentity();
	CAMLreturn(Val_unit);
}

value glstub_glLoadMatrixf(value v0)
{
	CAMLparam1(v0);
	GLfloat* lv0 = Data_bigarray_val(v0);
	glLoadMatrixf(lv0);
	CAMLreturn(Val_unit);
}

value glstub_glLoadPaletteFromModelViewMatrixOES(value v0)
{
	CAMLparam1(v0);
	glLoadPaletteFromModelViewMatrixOES();
	CAMLreturn(Val_unit);
}

value glstub_glLogicOp(value v0)
{
	CAMLparam1(v0);
	GLenum lv0 = Int_val(v0);
	glLogicOp(lv0);
	CAMLreturn(Val_unit);
}

value glstub_glMaterialf(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLenum lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	GLfloat lv2 = Double_val(v2);
	glMaterialf(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glMaterialfv(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLenum lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	GLfloat* lv2 = Data_bigarray_val(v2);
	glMaterialfv(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glMatrixIndexPointerOES(value v0, value v1, value v2, value v3)
{
	CAMLparam4(v0, v1, v2, v3);
	GLint lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	GLsizei lv2 = Int_val(v2);
	GLvoid* lv3 = (GLvoid *)(Is_long(v3) ? (void*)Long_val(v3) : ((Tag_val(v3) == String_tag)? (String_val(v3)) : (Data_bigarray_val(v3))));
	glMatrixIndexPointerOES(lv0, lv1, lv2, lv3);
	CAMLreturn(Val_unit);
}

value glstub_glMatrixMode(value v0)
{
	CAMLparam1(v0);
	GLenum lv0 = Int_val(v0);
	glMatrixMode(lv0);
	CAMLreturn(Val_unit);
}

value glstub_glMultMatrixf(value v0)
{
	CAMLparam1(v0);
	GLfloat* lv0 = Data_bigarray_val(v0);
	glMultMatrixf(lv0);
	CAMLreturn(Val_unit);
}

value glstub_glMultiTexCoord4f(value v0, value v1, value v2, value v3, value v4)
{
	CAMLparam5(v0, v1, v2, v3, v4);
	GLenum lv0 = Int_val(v0);
	GLfloat lv1 = Double_val(v1);
	GLfloat lv2 = Double_val(v2);
	GLfloat lv3 = Double_val(v3);
	GLfloat lv4 = Double_val(v4);
	glMultiTexCoord4f(lv0, lv1, lv2, lv3, lv4);
	CAMLreturn(Val_unit);
}

value glstub_glNormal3f(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLfloat lv0 = Double_val(v0);
	GLfloat lv1 = Double_val(v1);
	GLfloat lv2 = Double_val(v2);
	glNormal3f(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glNormalPointer(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLenum lv0 = Int_val(v0);
	GLsizei lv1 = Int_val(v1);
	GLvoid* lv2 = (GLvoid *)(Is_long(v2) ? (void*)Long_val(v2) : ((Tag_val(v2) == String_tag)? (String_val(v2)) : (Data_bigarray_val(v2))));
	glNormalPointer(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glOrthof(value v0, value v1, value v2, value v3, value v4, value v5)
{
	CAMLparam5(v0, v1, v2, v3, v4);
	CAMLxparam1(v5);
	GLfloat lv0 = Double_val(v0);
	GLfloat lv1 = Double_val(v1);
	GLfloat lv2 = Double_val(v2);
	GLfloat lv3 = Double_val(v3);
	GLfloat lv4 = Double_val(v4);
	GLfloat lv5 = Double_val(v5);
	glOrthof(lv0, lv1, lv2, lv3, lv4, lv5);
	CAMLreturn(Val_unit);
}

value glstub_glOrthof_byte(value * argv, int n)
{
	return glstub_glOrthof(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
}

value glstub_glPixelStorei(value v0, value v1)
{
	CAMLparam2(v0, v1);
	GLenum lv0 = Int_val(v0);
	GLint lv1 = Int_val(v1);
	glPixelStorei(lv0, lv1);
	CAMLreturn(Val_unit);
}

value glstub_glPointParameterf(value v0, value v1)
{
	CAMLparam2(v0, v1);
	GLenum lv0 = Int_val(v0);
	GLfloat lv1 = Double_val(v1);
	glPointParameterf(lv0, lv1);
	CAMLreturn(Val_unit);
}

value glstub_glPointParameterfv(value v0, value v1)
{
	CAMLparam2(v0, v1);
	GLenum lv0 = Int_val(v0);
	GLfloat* lv1 = Data_bigarray_val(v1);
	glPointParameterfv(lv0, lv1);
	CAMLreturn(Val_unit);
}

value glstub_glPointSize(value v0)
{
	CAMLparam1(v0);
	GLfloat lv0 = Double_val(v0);
	glPointSize(lv0);
	CAMLreturn(Val_unit);
}

value glstub_glPointSizePointerOES(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLenum lv0 = Int_val(v0);
	GLsizei lv1 = Int_val(v1);
	GLvoid* lv2 = (GLvoid *)(Is_long(v2) ? (void*)Long_val(v2) : ((Tag_val(v2) == String_tag)? (String_val(v2)) : (Data_bigarray_val(v2))));
	glPointSizePointerOES(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glPolygonOffset(value v0, value v1)
{
	CAMLparam2(v0, v1);
	GLfloat lv0 = Double_val(v0);
	GLfloat lv1 = Double_val(v1);
	glPolygonOffset(lv0, lv1);
	CAMLreturn(Val_unit);
}

value glstub_glPopMatrix(value v0)
{
	CAMLparam1(v0);
	glPopMatrix();
	CAMLreturn(Val_unit);
}

value glstub_glPushMatrix(value v0)
{
	CAMLparam1(v0);
	glPushMatrix();
	CAMLreturn(Val_unit);
}

value glstub_glReadPixels(value v0, value v1, value v2, value v3, value v4, value v5, value v6)
{
	CAMLparam5(v0, v1, v2, v3, v4);
	CAMLxparam2(v5, v6);
	GLint lv0 = Int_val(v0);
	GLint lv1 = Int_val(v1);
	GLsizei lv2 = Int_val(v2);
	GLsizei lv3 = Int_val(v3);
	GLenum lv4 = Int_val(v4);
	GLenum lv5 = Int_val(v5);
	GLvoid* lv6 = (GLvoid *)(Is_long(v6) ? (void*)Long_val(v6) : ((Tag_val(v6) == String_tag)? (String_val(v6)) : (Data_bigarray_val(v6))));
	glReadPixels(lv0, lv1, lv2, lv3, lv4, lv5, lv6);
	CAMLreturn(Val_unit);
}

value glstub_glReadPixels_byte(value * argv, int n)
{
	return glstub_glReadPixels(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6]);
}

value glstub_glRotatef(value v0, value v1, value v2, value v3)
{
	CAMLparam4(v0, v1, v2, v3);
	GLfloat lv0 = Double_val(v0);
	GLfloat lv1 = Double_val(v1);
	GLfloat lv2 = Double_val(v2);
	GLfloat lv3 = Double_val(v3);
	glRotatef(lv0, lv1, lv2, lv3);
	CAMLreturn(Val_unit);
}

value glstub_glSampleCoverage(value v0, value v1)
{
	CAMLparam2(v0, v1);
	GLclampf lv0 = Double_val(v0);
	GLboolean lv1 = Bool_val(v1);
	glSampleCoverage(lv0, lv1);
	CAMLreturn(Val_unit);
}

value glstub_glScalef(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLfloat lv0 = Double_val(v0);
	GLfloat lv1 = Double_val(v1);
	GLfloat lv2 = Double_val(v2);
	glScalef(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glScissor(value v0, value v1, value v2, value v3)
{
	CAMLparam4(v0, v1, v2, v3);
	GLint lv0 = Int_val(v0);
	GLint lv1 = Int_val(v1);
	GLsizei lv2 = Int_val(v2);
	GLsizei lv3 = Int_val(v3);
	glScissor(lv0, lv1, lv2, lv3);
	CAMLreturn(Val_unit);
}

value glstub_glShadeModel(value v0)
{
	CAMLparam1(v0);
	GLenum lv0 = Int_val(v0);
	glShadeModel(lv0);
	CAMLreturn(Val_unit);
}

value glstub_glStencilFunc(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLenum lv0 = Int_val(v0);
	GLint lv1 = Int_val(v1);
	GLuint lv2 = Int_val(v2);
	glStencilFunc(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glStencilMask(value v0)
{
	CAMLparam1(v0);
	GLuint lv0 = Int_val(v0);
	glStencilMask(lv0);
	CAMLreturn(Val_unit);
}

value glstub_glStencilOp(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLenum lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	GLenum lv2 = Int_val(v2);
	glStencilOp(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glTexCoordPointer(value v0, value v1, value v2, value v3)
{
	CAMLparam4(v0, v1, v2, v3);
	GLint lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	GLsizei lv2 = Int_val(v2);
	GLvoid* lv3 = (GLvoid *)(Is_long(v3) ? (void*)Long_val(v3) : ((Tag_val(v3) == String_tag)? (String_val(v3)) : (Data_bigarray_val(v3))));
	glTexCoordPointer(lv0, lv1, lv2, lv3);
	CAMLreturn(Val_unit);
}

value glstub_glTexEnvf(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLenum lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	GLfloat lv2 = Double_val(v2);
	glTexEnvf(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glTexEnvfv(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLenum lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	GLfloat* lv2 = Data_bigarray_val(v2);
	glTexEnvfv(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glTexEnvi(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLenum lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	GLint lv2 = Int_val(v2);
	glTexEnvi(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glTexEnviv(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLenum lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	GLint* lv2 = Data_bigarray_val(v2);
	glTexEnviv(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glTexImage2D(value v0, value v1, value v2, value v3, value v4, value v5, value v6, value v7, value v8)
{
	CAMLparam5(v0, v1, v2, v3, v4);
	CAMLxparam4(v5, v6, v7, v8);
	GLenum lv0 = Int_val(v0);
	GLint lv1 = Int_val(v1);
	GLint lv2 = Int_val(v2);
	GLsizei lv3 = Int_val(v3);
	GLsizei lv4 = Int_val(v4);
	GLint lv5 = Int_val(v5);
	GLenum lv6 = Int_val(v6);
	GLenum lv7 = Int_val(v7);
	GLvoid* lv8 = (GLvoid *)(Is_long(v8) ? (void*)Long_val(v8) : ((Tag_val(v8) == String_tag)? (String_val(v8)) : (Data_bigarray_val(v8))));
	glTexImage2D(lv0, lv1, lv2, lv3, lv4, lv5, lv6, lv7, lv8);
	CAMLreturn(Val_unit);
}

value glstub_glTexImage2D_byte(value * argv, int n)
{
	return glstub_glTexImage2D(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8]);
}

value glstub_glTexParameterf(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLenum lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	GLfloat lv2 = Double_val(v2);
	glTexParameterf(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glTexParameterfv(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLenum lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	GLfloat* lv2 = Data_bigarray_val(v2);
	glTexParameterfv(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glTexParameteri(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLenum lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	GLint lv2 = Int_val(v2);
	glTexParameteri(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glTexParameteriv(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLenum lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	GLint* lv2 = Data_bigarray_val(v2);
	glTexParameteriv(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glTexSubImage2D(value v0, value v1, value v2, value v3, value v4, value v5, value v6, value v7, value v8)
{
	CAMLparam5(v0, v1, v2, v3, v4);
	CAMLxparam4(v5, v6, v7, v8);
	GLenum lv0 = Int_val(v0);
	GLint lv1 = Int_val(v1);
	GLint lv2 = Int_val(v2);
	GLint lv3 = Int_val(v3);
	GLsizei lv4 = Int_val(v4);
	GLsizei lv5 = Int_val(v5);
	GLenum lv6 = Int_val(v6);
	GLenum lv7 = Int_val(v7);
	GLvoid* lv8 = (GLvoid *)(Is_long(v8) ? (void*)Long_val(v8) : ((Tag_val(v8) == String_tag)? (String_val(v8)) : (Data_bigarray_val(v8))));
	glTexSubImage2D(lv0, lv1, lv2, lv3, lv4, lv5, lv6, lv7, lv8);
	CAMLreturn(Val_unit);
}

value glstub_glTexSubImage2D_byte(value * argv, int n)
{
	return glstub_glTexSubImage2D(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8]);
}

value glstub_glTranslatef(value v0, value v1, value v2)
{
	CAMLparam3(v0, v1, v2);
	GLfloat lv0 = Double_val(v0);
	GLfloat lv1 = Double_val(v1);
	GLfloat lv2 = Double_val(v2);
	glTranslatef(lv0, lv1, lv2);
	CAMLreturn(Val_unit);
}

value glstub_glVertexPointer(value v0, value v1, value v2, value v3)
{
	CAMLparam4(v0, v1, v2, v3);
	GLint lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	GLsizei lv2 = Int_val(v2);
	GLvoid* lv3 = (GLvoid *)(Is_long(v3) ? (void*)Long_val(v3) : ((Tag_val(v3) == String_tag)? (String_val(v3)) : (Data_bigarray_val(v3))));
	glVertexPointer(lv0, lv1, lv2, lv3);
	CAMLreturn(Val_unit);
}

value glstub_glViewport(value v0, value v1, value v2, value v3)
{
	CAMLparam4(v0, v1, v2, v3);
	GLint lv0 = Int_val(v0);
	GLint lv1 = Int_val(v1);
	GLsizei lv2 = Int_val(v2);
	GLsizei lv3 = Int_val(v3);
	glViewport(lv0, lv1, lv2, lv3);
	CAMLreturn(Val_unit);
}

value glstub_glWeightPointerOES(value v0, value v1, value v2, value v3)
{
	CAMLparam4(v0, v1, v2, v3);
	GLint lv0 = Int_val(v0);
	GLenum lv1 = Int_val(v1);
	GLsizei lv2 = Int_val(v2);
	GLvoid* lv3 = (GLvoid *)(Is_long(v3) ? (void*)Long_val(v3) : ((Tag_val(v3) == String_tag)? (String_val(v3)) : (Data_bigarray_val(v3))));
	glWeightPointerOES(lv0, lv1, lv2, lv3);
	CAMLreturn(Val_unit);
}

