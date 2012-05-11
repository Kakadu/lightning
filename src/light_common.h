
#ifndef __LIGHT_COMMON_H__
#define __LIGHT_COMMON_H__

#define ERROR(fmt,args...) fprintf(stderr,fmt, ## args)

#ifdef LDEBUG
    #define PRINT_DEBUG(fmt,args...)  (fprintf(stderr,"[DEBUG(%s:%d)] ",__FILE__,__LINE__),fprintf(stderr,fmt, ## args),putc('\n',stderr))
#else
    #define PRINT_DEBUG(fmt,args...)
#endif

#ifndef RELEASE
#define checkGLErrors(fmt,args...) \
{ GLenum error = glGetError(); \
	int is_error = 0;\
	while (error != GL_NO_ERROR) { \
		printf("(%s:%d) gl error: %X [",__FILE__,__LINE__,error); \
		printf(fmt,## args);\
		printf("]\n"); \
		error = glGetError(); \
		is_error = 1; \
	}; \
	if (is_error) exit(1); \
}

#else
#define checkGLErrors(fmt,args...)
#endif


extern unsigned int MAX_GC_MEM;

#endif

