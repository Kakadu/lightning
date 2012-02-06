#include "render_stub.h"
#include <kazmath/GL/matrix.h>


#ifdef IOS
#define glDeleteVertexArrays glDeleteVertexArraysOES
#define glGenVertexArrays glGenVertexArraysOES
#define glBindVertexArray glBindVertexArrayOES
#else
#define glDeleteVertexArrays glDeleteVertexArraysAPPLE
#define glGenVertexArrays glGenVertexArraysAPPLE
#define glBindVertexArray glBindVertexArrayAPPLE
#endif

void checkGLErrors(char *where) {
	GLenum error = glGetError();
	int is_error = 0;
	while (error != GL_NO_ERROR) {
		printf("%s: gl error: %d\n",where,error);
		error = glGetError();
		is_error = 1;
	};
	if (is_error) exit(1);
}

//////////////////////////////////
/// COLORS


#define COLOR(r, g, b)     (((int)(r) << 16) | ((int)(g) << 8) | (int)(b))



#define COLOR_FROM_INT(c,alpha) (color4B){COLOR_PART_RED(c),COLOR_PART_GREEN(c),COLOR_PART_BLUE(c),alpha}

GLuint boundTextureID = 0;
int PMA = -1;
int separateBlend = 0;


void setPMAGLBlend () {
	if (PMA != 1) {
		glBlendFunc(GL_ONE,GL_ONE_MINUS_SRC_ALPHA);
		PMA = 1;
	};
}

void setNotPMAGLBlend () {
	if (PMA != 0) {
		if (separateBlend) {
			//printf("set separate not pma blend\n");
			glBlendFuncSeparate(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA,GL_ONE,GL_ONE);
		} else {
			//printf("set odinary not pma blend\n");
			glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
		};
		PMA = 0;
	};
}

#define setDefaultGLBlend setNotPMAGLBlend

void setupOrthographicRendering(GLfloat left, GLfloat right, GLfloat bottom, GLfloat top) {
	printf("set ortho rendering [%f:%f:%f:%f]\n",left,right,bottom,top);
  //glDisable(GL_DEPTH_TEST);
  glEnable(GL_BLEND);
  
	glViewport(left, top, (GLsizei)(right), (GLsizei)(bottom));
      
	setDefaultGLBlend();
	glClearColor(1.0,1.0,1.0,1.0);
	kmGLMatrixMode(KM_GL_PROJECTION);
	kmGLLoadIdentity();
      
	kmMat4 orthoMatrix;
	kmMat4OrthographicProjection(&orthoMatrix, left, right, bottom, top, -1024, 1024 );
	kmGLMultMatrix( &orthoMatrix );

	kmGLMatrixMode(KM_GL_MODELVIEW);
	kmGLLoadIdentity();

	checkGLErrors("set ortho rendering");
}


void ml_setupOrthographicRendering(value left,value right,value bottom,value top) {
	setupOrthographicRendering(Double_val(left),Double_val(right),Double_val(bottom),Double_val(top));
}

void ml_clear(value color,value alpha) {
	color3F c = COLOR3F_FROM_INT(Int_val(color));
	glClearColor(c.r,c.g,c.b,Double_val(alpha));
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}
/////////
/// Matrix
/////////

/*
{
  // | m[0] m[4] m[8]  m[12] |     | m11 m21 m31 m41 |     | a c 0 tx |
  // | m[1] m[5] m[9]  m[13] |     | m12 m22 m32 m42 |     | b d 0 ty |
  // | m[2] m[6] m[10] m[14] | <=> | m13 m23 m33 m43 | <=> | 0 0 1  0 |
  // | m[3] m[7] m[11] m[15] |     | m14 m24 m34 m44 |     | 0 0 0  1 |

  m[2] = m[3] = m[6] = m[7] = m[8] = m[9] = m[11] = m[14] = 0.0f;
  m[10] = m[15] = 1.0f;
  m[0] = t->a; m[4] = t->c; m[12] = t->tx;
  m[1] = t->b; m[5] = t->d; m[13] = t->ty;
}*/

void applyTransformMatrix(value matrix) {
	kmMat4 transfrom4x4;
  // Convert 3x3 into 4x4 matrix
	GLfloat *m = transfrom4x4.mat;
  m[2] = m[3] = m[6] = m[7] = m[8] = m[9] = m[11] = m[14] = 0.0f;
  m[10] = m[15] = 1.0f;
  m[0] = (GLfloat)Double_field(matrix,0); m[4] = (GLfloat)Double_field(matrix,2); m[12] = (GLfloat)Double_field(matrix,4);
  m[1] = (GLfloat)Double_field(matrix,1); m[5] = (GLfloat)Double_field(matrix,3); m[13] = (GLfloat)Double_field(matrix,5);

  kmGLMultMatrix( &transfrom4x4 );
}

void ml_push_matrix(value matrix) {
	kmGLPushMatrix();
	applyTransformMatrix(matrix);
}


void ml_restore_matrix(value p) {
	kmGLPopMatrix();
}


/////////////////////////////////////
/// SHADERS
//

typedef void (*GLInfoFunction)(GLuint program, GLenum pname, GLint* params);
typedef void (*GLLogFunction) (GLuint program, GLsizei bufsize, GLsizei* length, GLchar* infolog);

char* logForOpenGLObject(GLuint object, GLInfoFunction infoFunc, GLLogFunction logFunc) {
    GLint logLength = 0, charsWritten = 0;
    infoFunc(object, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength < 1) return NULL;

    char *logBytes = caml_stat_alloc(logLength);
    logFunc(object, logLength, &charsWritten, logBytes);
		return logBytes;
}

char* programLog(GLuint program) {
	return (logForOpenGLObject(program,(GLInfoFunction)&glGetProgramiv,(GLLogFunction)&glGetProgramInfoLog));
}

char* shaderLog(GLuint shader) {
  return (logForOpenGLObject(shader,(GLInfoFunction)&glGetShaderiv,(GLLogFunction)&glGetShaderInfoLog));
}

//

#define GLUINT(v) ((GLuint*)Data_custom_val(v))

static int gluint_compare(value gluint1,value gluint2) {
	GLuint t1 = *GLUINT(gluint1);
	GLuint t2 = *GLUINT(gluint2);
	if (t1 == t2) return 0;
	else {
		if (t1 < t2) return -1;
		return 1;
	}
}

static void shader_finalize(value shader) {
	GLuint s = *GLUINT(shader);
	glDeleteShader(s);
}

struct custom_operations shader_ops = {
  "pointer to shader id",
  shader_finalize,
 	gluint_compare,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};


value ml_compile_shader(value stype,value shader_src) {
	GLenum type;
	if (stype == 1) type = GL_VERTEX_SHADER; else type = GL_FRAGMENT_SHADER;
	GLuint shader = glCreateShader(type);
	const char *sh_src = String_val(shader_src);
	glShaderSource(shader, 1, &sh_src, NULL);
	glCompileShader(shader);
   
	GLint status;
	glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
 
  if( ! status ) {
		char msg[1024];
		char *log = shaderLog(shader);
    if( type == GL_VERTEX_SHADER ) {
			sprintf(msg,"vertex shader compilation failed: [%s]",log);
		} else {
      sprintf(msg,"frament shader compilation failed: [%s]",log);
		};
		caml_stat_free(log);
		glDeleteShader(shader);
		caml_failwith(msg);
  }
	value res = caml_alloc_custom(&shader_ops,sizeof(GLuint),0,1);
	printf("created shader: %d\n",shader);
	*GLUINT(res) = shader;
	return res;
}

GLuint currentShaderProgram = 0;

/*
static char   vertexAttribPosition = 0;
static char   vertexAttribColor = 0;
static char   vertexAttribTexCoords = 0;
*/



char vertexAttribPosition  = 0;
char vertexAttribColor = 0;
char vertexAttribTexCoords = 0;

void lgGLEnableVertexAttribs( unsigned int flags ) {   

  // Position
  char enablePosition = flags & lgVertexAttribFlag_Position;

  if( enablePosition != vertexAttribPosition ) {
    if( enablePosition ) {
			printf("enable vertex attrib array\n");
      glEnableVertexAttribArray( lgVertexAttrib_Position );
		}
    else {
			printf("disable vertex attrib array\n");
      glDisableVertexAttribArray( lgVertexAttrib_Position );
		}
  
    vertexAttribPosition = enablePosition;
  } 
    
  // Color
  char enableColor = flags & lgVertexAttribFlag_Color;
  
  if( enableColor != vertexAttribColor ) {
    if( enableColor )
      glEnableVertexAttribArray( lgVertexAttrib_Color );
    else
      glDisableVertexAttribArray( lgVertexAttrib_Color );
    
    vertexAttribColor = enableColor;
  }

  // Tex Coords
  char enableTexCoords = flags & lgVertexAttribFlag_TexCoords;
  
  if( enableTexCoords != vertexAttribTexCoords ) {
    if( enableTexCoords ) 
      glEnableVertexAttribArray( lgVertexAttrib_TexCoords );
    else
      glDisableVertexAttribArray( lgVertexAttrib_TexCoords );
    
    vertexAttribTexCoords = enableTexCoords;
  }
} 


/*
	void *specUniforms;
	uniformFun bindUniforms;
*/

#define SPROGRAM(v) *((sprogram**)Data_custom_val(v))

static void program_finalize(value program) {
	sprogram *p = SPROGRAM(program);
	printf("finalize prg: %d\n",p->program);
	if (p->uniforms != NULL) caml_stat_free(p->uniforms);
  if( p->program == currentShaderProgram ) currentShaderProgram = 0;
	glDeleteProgram(p->program);
	caml_stat_free(p);
}

static int program_compare(value p1,value p2) {
	sprogram *pr1 = SPROGRAM(p1);
	sprogram *pr2 = SPROGRAM(p2);
	if (pr1->program == pr2->program) return 0;
	else {
		if (pr1->program < pr2->program) return -1;
		return 1;
	}
}

struct custom_operations program_ops = {
  "pointer to program id",
  program_finalize,
 	program_compare,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

void lgGLUseProgram( GLuint program ) {
  if( program != currentShaderProgram ) {
    currentShaderProgram = program;
    glUseProgram(program);
  }
}

void lgGLBindTexture(GLuint newTextureID, int newPMA) {
	//printf("texture: %d, %d\n",newTextureID,newPMA);
	if (boundTextureID != newTextureID) {
		glBindTexture(GL_TEXTURE_2D,newTextureID);
		boundTextureID = newTextureID;
	};
	if (newPMA != PMA) {
		if (newPMA) glBlendFunc(GL_ONE,GL_ONE_MINUS_SRC_ALPHA); else 
			if (separateBlend)
				glBlendFuncSeparate(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA,GL_ONE,GL_ONE);
			else
				glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
		PMA = newPMA;
	}
}

value ml_program_create(value vShader,value fShader,value attributes,value uniforms) {
	CAMLparam4(vShader,fShader,attributes,uniforms);
	CAMLlocal2(prg,res);
	GLuint program =  glCreateProgram();
	printf("create program %d\n",program);
	glAttachShader(program, *GLUINT(vShader)); 
	checkGLErrors("attach shader 1");
	glAttachShader(program, *GLUINT(fShader)); 
	checkGLErrors("attach shader 2");
	// bind attributes
	value lst = attributes;
	value el;
	while (lst != 1) {
		el = Field(lst,0);
		int attr = Int_val(Field(el,0));
		value name = Field(el,1);
		glBindAttribLocation(program,attr,String_val(name));
		printf("attribute: %d\n",attr);
		lst = Field(lst,1);
	}
	checkGLErrors("locations binded");
	/*printf("AFTER ATTRIBS\n");
	for (int i = 0; i < lgVertexAttrib_MAX; i++) {
		printf("attrib: %d = %d\n",i,sp->attributes[i]);
	}*/
	// Link
	glLinkProgram(program);
	// DEBUG
	GLint status;
	glValidateProgram(program);
	glGetProgramiv(program, GL_LINK_STATUS, &status);
	if (status == GL_FALSE) {
    glDeleteProgram( program );
    caml_failwith("Failed to link program");
  }

	sprogram *sp = caml_stat_alloc(sizeof(sprogram));

	checkGLErrors("before uniforms");

	sp->std_uniforms[lgUniformMVPMatrix] = glGetUniformLocation(program, "u_MVPMatrix");
	printf("std_uniform: matrix: %d\n",sp->std_uniforms[lgUniformMVPMatrix]);
	sp->std_uniforms[lgUniformAlpha] = glGetUniformLocation(program, "u_parentAlpha");
	printf("std_uniform: parentAlpha: %d\n",sp->std_uniforms[lgUniformAlpha]);
	/*
	if (has_texture) {
		GLint loc = glGetUniformLocation(program,"u_texture");
		sp->uniforms[lgUniformSampler] = loc;
		lgGLUseProgram( program );
		glUniform1i(loc, 0 );
	};
	*/

	checkGLErrors("create program bind uniforms");

	int uniformsLen = Wosize_val(uniforms);
	if (uniformsLen > 0) {
		printf("uniformsLen = %d\n",uniformsLen);
		lgGLUseProgram(program);
		sp->uniforms = (GLint*)caml_stat_alloc(sizeof(GLuint)*uniformsLen);
		GLuint loc;
		for (int idx = 0; idx < uniformsLen; idx++) {
			value el = Field(uniforms,idx);
			loc = glGetUniformLocation(program, String_val(Field(el,0)));
			printf("uniform: '%s' = %d\n",String_val(Field(el,0)),loc);
			sp->uniforms[idx] = loc;
			value u = Field(el,1);
			if (Is_block(u)) {
				value v = Field(u,0);
				switch Tag_val(u) {
					case 0: glUniform1i(loc,Long_val(v)); break;
					case 1: 
						glUniform2i(loc,Long_val(Field(v,0)),Long_val(Field(v,1)));
						break;
					case 2:
						glUniform3i(loc,Long_val(Field(v,0)),Long_val(Field(v,1)),Long_val(Field(v,2)));
						break;
					case 3:
						glUniform1f(loc,Double_val(v));
						break;
					case 4:
						glUniform2f(loc,Double_val(Field(v,0)),Double_val(Field(v,1)));
						break;
					default: printf("unimplemented uniform value\n");
				};
			};
		};
	} else sp->uniforms = NULL;
	checkGLErrors("uniform binded");
	sp->program = program;
	prg = caml_alloc_custom(&program_ops,sizeof(*sp),0,1);
	SPROGRAM(prg) = sp;
	res = caml_alloc_tuple(3);
	Store_field(res,0,prg);
	Store_field(res,1,vShader);
	Store_field(res,2,fShader);
	CAMLreturn(res);
}



void lgGLUniformModelViewProjectionMatrix(sprogram *sp) {
  kmMat4 matrixP;
  kmMat4 matrixMV;
  kmMat4 matrixMVP;

  kmGLGetMatrix(KM_GL_PROJECTION, &matrixP );
  kmGLGetMatrix(KM_GL_MODELVIEW, &matrixMV );

  kmMat4Multiply(&matrixMVP, &matrixP, &matrixMV);

	//printf("matrix uniform location: %d\n",sp->uniforms[lgUniformMVPMatrix]);
  glUniformMatrix4fv( sp->std_uniforms[lgUniformMVPMatrix], 1, GL_FALSE, matrixMVP.mat);
}


////////////////////////////////////
/////// QUADS 
//! a Point with a vertex point, and color 4B
typedef struct 
{ 
  //! vertices (2F)
  vertex2F    v;
  //! colors (4B)   
  color4B   c;
} lgQVertex;

//! 4 ccV3F_C4F_T2F
typedef struct 
{
  //! top left
  lgQVertex tl;
  //! bottom left
  lgQVertex bl;
  //! top right
  lgQVertex tr;
  //! bottom right
  lgQVertex br;
} lgQuad;


#define QUAD(v) ((lgQuad**)Data_custom_val(v))

static void quad_finalize(value quad) {
	lgQuad *q = *QUAD(quad);
	caml_stat_free(q);
}

struct custom_operations quad_ops = {
  "pointer to a quad",
  quad_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

value ml_quad_create(value width,value height,value color,value alpha) {
	CAMLparam0();
	lgQuad *q = (lgQuad*)caml_stat_alloc(sizeof(lgQuad));
	int clr = Int_val(color);
	color4B c = COLOR_FROM_INT(clr,(GLubyte)(Double_val(alpha) * 255));
	//printf("quad color: [%hhu,%hhu,%hhu,%hhu]\n",c.r,c.g,c.b,c.a);
	q->bl.v = (vertex2F) { 0, 0 };
	q->bl.c = c;
	q->br.v = (vertex2F) { Double_val(width)};
	q->br.c = c;
	q->tl.v = (vertex2F) { 0, Double_val(height)};
	q->tl.c = c;
	q->tr.v = (vertex2F) { Double_val(width), Double_val(height) };
	q->tr.c = c;
	value res = caml_alloc_custom(&quad_ops,sizeof(lgQuad*),0,1); // 
	*QUAD(res) = q;
	CAMLreturn(res);
}

value ml_quad_points(value quad) { 
	CAMLparam1(quad);
	CAMLlocal4(p1,p2,p3,p4);
	lgQuad *q = *QUAD(quad);
	int s = 2 * Double_wosize;
	p1 = caml_alloc(s,Double_array_tag);
	Store_double_field(p1, 0, (double)q->bl.v.x);
	Store_double_field(p1, 1, (double)q->bl.v.y);
	p2 = caml_alloc(s,Double_array_tag);
	Store_double_field(p2, 0, (double)q->br.v.x);
	Store_double_field(p2, 1, (double)q->br.v.y);
	p3 = caml_alloc(s,Double_array_tag);
	Store_double_field(p3, 0, (double)q->tl.v.x);
	Store_double_field(p3, 1, (double)q->tl.v.y);
	p4 = caml_alloc(2,Double_array_tag);
	Store_double_field(p4, 0, (double)q->tr.v.x);
	Store_double_field(p4, 1, (double)q->tr.v.y);
	value res = caml_alloc_small(4,0);
	Field(res,0) = p1;
	Field(res,1) = p2;
	Field(res,2) = p3;
	Field(res,3) = p4;
	CAMLreturn(res);
}

value ml_quad_color(value quad) {
	lgQuad *q = *QUAD(quad);
	return Int_val((COLOR(q->bl.c.r,q->bl.c.b,q->bl.c.g)));
}

void ml_quad_set_color(value quad,value color) {
	lgQuad *q = *QUAD(quad);
	long clr = Int_val(color);
	color4B c = COLOR_FROM_INT(clr,q->bl.c.a);
	q->bl.c = c;
	q->br.c = c;
	q->tl.c = c;
	q->tr.c = c;
}

value ml_quad_alpha(value quad) {
	lgQuad *q = *QUAD(quad);
	return (caml_copy_double((double)(q->bl.c.a / 255)));
}

void ml_quad_set_alpha(value quad,value alpha) {
	lgQuad *q = *QUAD(quad);
	GLubyte a = (GLubyte)(Double_val(alpha) * 255.0);
	printf("set quad alpha to: %d\n",a);
	q->bl.c.a = a;
	q->br.c.a = a;
	q->tl.c.a = a;
	q->tr.c.a = a;
}

void ml_quad_colors(value quad) {
}


void print_vertex(lgQVertex *qv) {
	printf("v = [%f:%f], c = [%hhu,%hhu,%hhu,%hhu]\n",qv->v.x,qv->v.y,qv->c.r,qv->c.g,qv->c.b,qv->c.a);
}

void print_quad(lgQuad *q) {
	printf("==== quad =====\n");
	printf("bl: ");
	print_vertex(&(q->bl));
	printf("br: ");
	print_vertex(&(q->br));
	printf("tl: ");
	print_vertex(&(q->tl));
	printf("tr: ");
	print_vertex(&(q->tr));
}

void ml_quad_render(value matrix, value program, value alpha, value quad) {
	lgQuad *q = *QUAD(quad);
	checkGLErrors("start");

	sprogram *sp = SPROGRAM(Field(Field(program,0),0));
	lgGLUseProgram(sp->program);
	checkGLErrors("quad render use program");

	kmGLPushMatrix();
	applyTransformMatrix(matrix);
	lgGLUniformModelViewProjectionMatrix(sp);
	checkGLErrors("image render bind matrix uniform");

	glUniform1f(sp->std_uniforms[lgUniformAlpha],(GLfloat)(alpha == Val_unit ? 1 : Double_val(Field(alpha,0))));

	lgGLEnableVertexAttribs(lgVertexAttribFlag_PosColor);

	setNotPMAGLBlend();
	long offset = (long)q;

	#define kQuadSize sizeof(q->bl)

  // vertex
  int diff = offsetof( lgQVertex, v);
  glVertexAttribPointer(lgVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, kQuadSize, (void*) (offset + diff));
	checkGLErrors("bind vertex pointer");
  
  // color
  diff = offsetof( lgQVertex, c);
  glVertexAttribPointer(lgVertexAttrib_Color, 4, GL_UNSIGNED_BYTE, GL_TRUE, kQuadSize, (void*)(offset + diff));
  
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	checkGLErrors("draw arrays");

	kmGLPopMatrix();
}

///////////////
// Images
//


#define TEXQUAD(v) ((lgTexQuad**)Data_custom_val(v))

static void tex_quad_finalize(value tquad) {
	lgTexQuad *tq = *TEXQUAD(tquad);
	caml_stat_free(tq);
}

struct custom_operations tex_quad_ops = {
  "pointer to a quad",
  tex_quad_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};


void set_image_uv(lgTexQuad *tq, value clipping) {
	if (clipping != 1) {
		value c = Field(clipping,0);
		double x = Double_field(c,0);
		double y = Double_field(c,1);
		double width = Double_field(c,2);
		double height = Double_field(c,3);
		tq->bl.tex.u = x;
		tq->bl.tex.v = y;
		tq->br.tex.u = x + width;
		tq->br.tex.v = y;
		tq->tl.tex.u = x;
		tq->tl.tex.v = y + height;
		tq->tr.tex.u = x + width;
		tq->tr.tex.v = y + height;
	} else {
		tq->bl.tex = (tex2F){0,0};
		tq->br.tex = (tex2F){1,0};
		tq->tl.tex = (tex2F){0,1};
		tq->tr.tex = (tex2F){1,1};
	};
}


void print_tex_vertex(lgTexVertex *qv) {
	PRINT_DEBUG("v = [%f:%f], c = [%hhu,%hhu,%hhu,%hhu], tex = [%f:%f] \n",qv->v.x,qv->v.y,qv->c.r,qv->c.g,qv->c.b,qv->c.a,qv->tex.u,qv->tex.v);
}
void print_image(lgTexQuad *tq) {
	printf("==== image =====\n");
	printf("bl: ");
	print_tex_vertex(&(tq->bl));
	printf("br: ");
	print_tex_vertex(&(tq->br));
	printf("tl: ");
	print_tex_vertex(&(tq->tl));
	printf("tr: ");
	print_tex_vertex(&(tq->tr));
}
//
value ml_image_create(value width,value height,value clipping,value color,value alpha) {
	CAMLparam5(width,height,clipping,color,alpha);
	lgTexQuad *tq = (lgTexQuad*)caml_stat_alloc(sizeof(lgTexQuad));
	int clr = Int_val(color);
	color4B c = COLOR_FROM_INT(clr,(GLubyte)(Double_val(alpha) * 255));
	tq->bl.v = (vertex2F){0,0};
	tq->bl.c = c;
	tq->br.v = (vertex2F) { Double_val(width),0.};
	tq->br.c = c;
	tq->tl.v = (vertex2F) { 0, Double_val(height)};
	tq->tl.c = c;
	tq->tr.v = (vertex2F) { Double_val(width), Double_val(height) };
	tq->tr.c = c;
	set_image_uv(tq,clipping);
	value res = caml_alloc_custom(&tex_quad_ops,sizeof(lgTexQuad*),0,1); // 
	*TEXQUAD(res) = tq;
	//print_image(tq);
	CAMLreturn(res);
}

value ml_image_points(value image) {
	CAMLparam1(image);
	CAMLlocal5(p1,p2,p3,p4,res);
	lgTexQuad *tq = *TEXQUAD(image);
	int s = 2 * Double_wosize;
	p1 = caml_alloc(s,Double_array_tag);
	Store_double_field(p1, 0, (double)tq->bl.v.x);
	Store_double_field(p1, 1, (double)tq->bl.v.y);
	p2 = caml_alloc(s,Double_array_tag);
	Store_double_field(p2, 0, (double)tq->br.v.x);
	Store_double_field(p2, 1, (double)tq->br.v.y);
	p3 = caml_alloc(s,Double_array_tag);
	Store_double_field(p3, 0, (double)tq->tl.v.x);
	Store_double_field(p3, 1, (double)tq->tl.v.y);
	p4 = caml_alloc(s,Double_array_tag);
	Store_double_field(p4, 0, (double)(tq->tr.v.x));
	Store_double_field(p4, 1, (double)(tq->tr.v.y));
	res = caml_alloc_small(4,0);
	Field(res,0) = p1;
	Field(res,1) = p2;
	Field(res,2) = p3;
	Field(res,3) = p4;
	CAMLreturn(res);
}

value ml_image_color(value image) {
	lgTexQuad *tq = *TEXQUAD(image);
	return Int_val((COLOR(tq->bl.c.r,tq->bl.c.b,tq->bl.c.g)));
}


void ml_image_set_color(value image,value color) {
	lgTexQuad *tq = *TEXQUAD(image);
	long clr = Int_val(color);
	color4B c = COLOR_FROM_INT(clr,tq->bl.c.a);
	tq->bl.c = c;
	tq->br.c = c;
	tq->tl.c = c;
	tq->tr.c = c;
}

void ml_image_set_alpha(value image,value alpha) {
	lgTexQuad *tq = *TEXQUAD(image);
	GLubyte a = (GLubyte)(Double_val(alpha) * 255.0);
	tq->bl.c.a = a;
	tq->br.c.a = a;
	tq->tl.c.a = a;
	tq->tr.c.a = a;
}

void ml_image_update(value image, value width, value height, value clipping) {
	lgTexQuad *tq = *TEXQUAD(image);
	tq->br.v = (vertex2F) { Double_val(width)};
	tq->tl.v = (vertex2F) { 0, Double_val(height)};
	tq->tr.v = (vertex2F) { Double_val(width), Double_val(height) };
	set_image_uv(tq,clipping);
}

#define SWAP_TEX_COORDS(c1,c2) {tex2F tmp = tq->c1.tex, tq->c1.tex = tq->c2.tex,tq->c2.tex = tmp}


void ml_image_flip_tex_x(value image) {
	lgTexQuad *tq = *TEXQUAD(image);
	tex2F tmp = tq->tl.tex;
	tq->tl.tex = tq->tr.tex;
	tq->tr.tex = tmp;
	tmp = tq->bl.tex;
	tq->bl.tex = tq->br.tex;
	tq->br.tex = tmp;
}

void ml_image_flip_tex_y(value image) {
	lgTexQuad *tq = *TEXQUAD(image);
	tex2F tmp = tq->tl.tex;
	tq->tl.tex = tq->bl.tex;
	tq->bl.tex = tmp;
	tmp = tq->tr.tex;
	tq->tr.tex = tq->br.tex;
	tq->br.tex = tmp;
}

void ml_image_render(value matrix,value program, value textureID, value pma, value alpha, value image) {
	lgTexQuad *tq = *TEXQUAD(image);
	checkGLErrors("start");

	sprogram *sp = SPROGRAM(Field(Field(program,0),0));
	//printf("render image: %d with prg %d\n",Long_val(textureID),sp->program);
	lgGLUseProgram(sp->program);
	checkGLErrors("image render use program");

	kmGLPushMatrix();
	applyTransformMatrix(matrix);
	lgGLUniformModelViewProjectionMatrix(sp);
	checkGLErrors("bind matrix uniform");

	glUniform1f(sp->std_uniforms[lgUniformAlpha],(GLfloat)(alpha == Val_unit ? 1 : Double_val(Field(alpha,0))));

	lgGLEnableVertexAttribs(lgVertexAttribFlag_PosTexColor);

	value fs = Field(program,1);
	if (fs != Val_unit) {
		filter *f = FILTER(Field(fs,0));
		f->render(sp,f->data);
	};
	lgGLBindTexture(Long_val(textureID),Int_val(pma));
	checkGLErrors("bind texture");

	//print_image(tq);

	long offset = (long)tq;

  // vertex
  int diff = offsetof( lgTexVertex, v);
	//glEnableVertexAttribArray(lgVertexAttrib_Position);
  glVertexAttribPointer(lgVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, TexVertexSize, (void*) (offset + diff));
	checkGLErrors("bind vertex pointer");
  
  // color
  diff = offsetof( lgTexVertex, c);
	//glEnableVertexAttribArray(lgVertexAttrib_Color);
  glVertexAttribPointer(lgVertexAttrib_Color, 4, GL_UNSIGNED_BYTE, GL_TRUE, TexVertexSize, (void*)(offset + diff));

  // texture coords
  diff = offsetof( lgTexVertex, tex);
	//glEnableVertexAttribArray(lgVertexAttrib_TexCoords);
  glVertexAttribPointer(lgVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, TexVertexSize, (void*)(offset + diff));
  
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	checkGLErrors("draw arrays");
	kmGLPopMatrix();
};

void ml_image_render_byte(value * argv, int n) {
	ml_image_render(argv[0],argv[1],argv[2],argv[3],argv[4],argv[5]);
}


/////////////////////////////
//// RENDER TEXTURE
////////////////////


value ml_rendertexture_create(value format, value color, value alpha, value width,value height) {
	GLuint mTextureID;
	checkGLErrors("start create rendertexture");
	glGenTextures(1, &mTextureID);
	glBindTexture(GL_TEXTURE_2D, mTextureID);// бинд с кэшем нахуй бля 
	boundTextureID = mTextureID;
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); 
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE); 
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE); 
	int w = Long_val(width),h = Long_val(height);
	PRINT_DEBUG("create rtexture: [%d:%d]\n",w,h);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	checkGLErrors("tex image 2d from framebuffer");
	glBindTexture(GL_TEXTURE_2D,0);
	boundTextureID = 0;
	GLuint mFramebuffer;
	GLint oldBuffer;
	glGetIntegerv(GL_FRAMEBUFFER_BINDING,&oldBuffer);
	glGenFramebuffers(1, &mFramebuffer);
	PRINT_DEBUG("generated new framebuffer: %d\n",mFramebuffer);
	glBindFramebuffer(GL_FRAMEBUFFER, mFramebuffer);
	checkGLErrors("bind framebuffer");
	glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, mTextureID,0);
	checkGLErrors("framebuffer texture");
	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
		PRINT_DEBUG("framebuffer status: %d\n",glCheckFramebufferStatus(GL_FRAMEBUFFER));
		caml_failwith("failed to create frame buffer for render texture");
	};
	//color3F c = COLOR3F_FROM_INT(Int_val(color));
	//glClearColor(c.r,c.g,c.b,(GLclampf)Double_val(alpha));
	//glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glBindFramebuffer(GL_FRAMEBUFFER,oldBuffer);
	//printf("old buffer: %d\n",oldBuffer);
	value result = caml_alloc_small(2,0);
	Field(result,0) = Val_long(mFramebuffer);
	Field(result,1) = Val_long(mTextureID);
	return result;
};

void ml_resize_texture(value textureID,value width,value height) {
	GLuint mTextureID = Long_val(textureID);
	glBindTexture(GL_TEXTURE_2D, mTextureID);
	boundTextureID = 0;
	glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,Long_val(width),Long_val(height),0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);
}

void get_framebuffer_state(framebuffer_state *s) {
	GLint oldBuffer;
	glGetIntegerv(GL_FRAMEBUFFER_BINDING,&oldBuffer);
	GLint viewPort[4];
	glGetIntegerv(GL_VIEWPORT,viewPort);
	s->frameBuffer = oldBuffer;
	s->width = viewPort[2];
	s->height = viewPort[3];
}

value ml_activate_framebuffer(value framebufferID,value width,value height) {
	//printf("bind framebuffer: %ld\n",Long_val(framebufferID));

	framebuffer_state *s = caml_stat_alloc(sizeof(framebuffer_state));
	get_framebuffer_state(s);

	glBindFramebuffer(GL_FRAMEBUFFER,Long_val(framebufferID));

	checkGLErrors("bind framebuffer");

	glViewport(0, 0,Long_val(width), Long_val(height));

	kmGLMatrixMode(KM_GL_PROJECTION);
	kmGLPushMatrix();
	kmGLLoadIdentity();
      
	kmMat4 orthoMatrix;
	kmMat4OrthographicProjection(&orthoMatrix, 0, (GLfloat)Long_val(width), 0, (GLfloat)Long_val(height), -1024, 1024 );
	kmGLMultMatrix( &orthoMatrix );

	kmGLMatrixMode(KM_GL_MODELVIEW);
	kmGLPushMatrix();
	kmGLLoadIdentity();
	//if (offset != 1) kmGLTranslatef(Double_field(Field(offset,0),0),Double_field(Field(offset,0),1),-10);
	/*
	if (matrix != 1) {
		value mtrx = Field(matrix,0);
		kmMat4 transfrom4x4;
		// Convert 3x3 into 4x4 matrix
		GLfloat *m = transfrom4x4.mat;
		m[2] = m[3] = m[6] = m[7] = m[8] = m[9] = m[11] = m[14] = 0.0f;
		m[10] = m[15] = 1.0f;
		m[0] = (GLfloat)Double_field(mtrx,0); m[4] = (GLfloat)Double_field(mtrx,2); m[12] = (GLfloat)Double_field(mtrx,4);
		m[1] = (GLfloat)Double_field(mtrx,1); m[5] = (GLfloat)Double_field(mtrx,3); m[13] = (GLfloat)Double_field(mtrx,5);
		kmGLLoadMatrix(&transfrom4x4);
	} else 
	*/
  //glDisable(GL_DEPTH_TEST);
	//glEnable(GL_BLEND);
	//lgGLBindTexture(0,0);
	//setNotPMAGLBlend();
	separateBlend = 1;
	PMA = -1;
	return (value)s; 
}

void set_framebuffer_state(framebuffer_state *s) {
	glBindFramebuffer(GL_FRAMEBUFFER,s->frameBuffer);
	glViewport(0, 0, s->width, s->height);
}

void ml_deactivate_framebuffer(value ostate) {
	framebuffer_state *s = (framebuffer_state*)ostate;
	set_framebuffer_state(s);
	kmGLMatrixMode(KM_GL_PROJECTION);
	kmGLPopMatrix();
	kmGLMatrixMode(KM_GL_MODELVIEW);
	kmGLPopMatrix();
	separateBlend = 0;
	PMA = -1;
	caml_stat_free(s);
}


void ml_delete_framebuffer(value framebuffer) {
	GLuint fbID = Long_val(framebuffer);
	//printf("delete framebuffer: %d\n",fbID);
	glDeleteFramebuffers(1,&fbID);
}




typedef struct {
	GLuint vaoname;
	GLuint buffersVBO[2];
	int n_of_quads;
	int index_size;
} atlas_t;


#define ATLAS(v) *((atlas_t**)Data_custom_val(v))

static void atlas_finalize(value atlas) {
	atlas_t *atl = ATLAS(atlas);
	glDeleteBuffers(2,atl->buffersVBO);
  glDeleteVertexArrays(1, &atl->vaoname);
	caml_stat_free(atl);
}

struct custom_operations atlas_ops = {
  "pointer to atlas gl buffers",
  atlas_finalize,
 	custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

/// ATLAS
value ml_atlas_init(value unit) { 
	CAMLparam0();

	atlas_t *atl = caml_stat_alloc(sizeof(atlas_t));

	glGenVertexArrays(1, &atl->vaoname);
  glBindVertexArray(atl->vaoname);

  glGenBuffers(2, atl->buffersVBO);


	atl->index_size = 0;
	atl->n_of_quads = 0;

  glBindBuffer(GL_ARRAY_BUFFER, atl->buffersVBO[0]);
  //glBufferData(GL_ARRAY_BUFFER, sizeof(quads_[0]) * capacity_, quads_, GL_DYNAMIC_DRAW);

  // vertices
	glEnableVertexAttribArray(lgVertexAttrib_Position);
  glVertexAttribPointer(lgVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, TexVertexSize, (GLvoid*) offsetof( lgTexVertex, v));
 
  // colors
	glEnableVertexAttribArray(lgVertexAttrib_Color);
  glVertexAttribPointer(lgVertexAttrib_Color, 4, GL_UNSIGNED_BYTE, GL_TRUE, TexVertexSize, (GLvoid*) offsetof( lgTexVertex, c));
 
  // tex coords
	glEnableVertexAttribArray(lgVertexAttrib_TexCoords);
  glVertexAttribPointer(lgVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, TexVertexSize, (GLvoid*) offsetof( lgTexVertex, tex));
 
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,atl->buffersVBO[1]);

  glBindVertexArray(0);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
  glBindBuffer(GL_ARRAY_BUFFER, 0);

	checkGLErrors("atlas init");

	value result = caml_alloc_custom(&atlas_ops,sizeof(atlas_t*),0,1);
	ATLAS(result) = atl;
	CAMLreturn(result);
}

// TODO: finzlie this static arrays 
static GLushort *atlas_indices = NULL;
static int atlas_indices_len = 0;

static lgTexQuad *atlas_quads = NULL;
static int atlas_quads_len = 0;


// assume that quads it's dynarray
void ml_atlas_render(value atlas, value matrix,value program, value textureID,value pma, value alpha, value quads) {
	atlas_t *atl = ATLAS(atlas);
	sprogram *sp = SPROGRAM(Field(Field(program,0),0));
	lgGLUseProgram(sp->program);

	kmGLPushMatrix();
	applyTransformMatrix(matrix);
	lgGLUniformModelViewProjectionMatrix(sp);
	checkGLErrors("bind matrix uniform");

	glUniform1f(sp->std_uniforms[lgUniformAlpha],(GLfloat)(Double_val(alpha)));

	value fs = Field(program,1);
	if (fs != Val_unit) {
		filter *f = FILTER(Field(fs,0));
		f->render(sp,f->data);
	};

	lgGLBindTexture(Long_val(textureID),Int_val(pma));

	if (quads != Val_unit) { // it's not None array is dirty, resend it to gl
		value children = Field(quads,0);
		value arr = Field(children,0);
		int len = Int_val(Field(children,1));
		int arrlen = Wosize_val(arr);
		PRINT_DEBUG("upgrade quads. indexlen: %d, quadslen: %d\n",arrlen,len);
		int i;

		if (arrlen != atl->index_size) { // we need resend index
			if (atlas_indices_len < arrlen) {
				atlas_indices = realloc(atlas_indices,sizeof(GLushort) * arrlen * 6);
				atlas_indices_len = arrlen;
			};
			for(i = 0; i < arrlen; i++) {
				atlas_indices[i*6+0] = i*4+0;
				atlas_indices[i*6+1] = i*4+0;
				atlas_indices[i*6+2] = i*4+2;
				atlas_indices[i*6+3] = i*4+1;
				atlas_indices[i*6+4] = i*4+3;
				atlas_indices[i*6+5] = i*4+3;
			};
			glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, atl->buffersVBO[1]);
			glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLushort) * arrlen * 6, atlas_indices, GL_STATIC_DRAW);
			glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
			atl->index_size = arrlen;
		};

		if (len > atlas_quads_len) {
			atlas_quads = realloc(atlas_quads,len * sizeof(lgTexQuad));
		}
		lgTexQuad *q;
		value child,bounds,clipping;
		color4B c;

		for (i = 0; i < len; i++) {
			child = Field(arr,i);
			bounds = Field(child,1);
			clipping = Field(child,2);
			c = COLOR_FROM_INT(Int_val(Field(child,6)),(GLubyte)(Double_val(Field(child,7)) * 255));

			q = atlas_quads + i;

			q->bl.c = c;
			q->bl.v = (vertex2F){Double_field(bounds,0),Double_field(bounds,1)};
			q->bl.tex = (tex2F){Double_field(clipping,0),Double_field(clipping,1)};

			q->br.c = c;
			q->br.v = (vertex2F){q->bl.v.x + Double_field(bounds,2),q->bl.v.y};
			q->br.tex = (tex2F){q->bl.tex.u + Double_field(clipping,2),q->bl.tex.v};

			q->tl.c = c;
			q->tl.v = (vertex2F){q->bl.v.x,q->bl.v.y + Double_field(bounds,3)};
			q->tl.tex = (tex2F){q->bl.tex.u,q->bl.tex.v + Double_field(clipping,3)};

			q->tr.c = c;
			q->tr.v = (vertex2F){q->br.v.x,q->tl.v.y};
			q->tr.tex = (tex2F){q->br.tex.u,q->tl.tex.v};

		};


		/*
		for (i = 0; i < len; i++) {
			print_image(atlas_quads + i);
		}; */

		glBindBuffer(GL_ARRAY_BUFFER, atl->buffersVBO[0]);
		glBufferData(GL_ARRAY_BUFFER, sizeof(lgTexQuad) * len, atlas_quads, GL_DYNAMIC_DRAW);
		glBindBuffer(GL_ARRAY_BUFFER, 0);
		atl->n_of_quads = len;
		

	};
	
	/*
	glBindBuffer(GL_ARRAY_BUFFER,atl->buffersVBO[0]);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,atl->buffersVBO[1]);

	lgGLEnableVertexAttribs(lgVertexAttribFlag_PosColorTex);

	// vertices
	glVertexAttribPointer(lgVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, TexVertexSize, (GLvoid*) offsetof( lgTexVertex, v));
	// colors
	glVertexAttribPointer(lgVertexAttrib_Color, 4, GL_UNSIGNED_BYTE, GL_TRUE, TexVertexSize, (GLvoid*) offsetof( lgTexVertex, c));
	// tex coords
	glVertexAttribPointer(lgVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, TexVertexSize, (GLvoid*) offsetof( lgTexVertex, tex));

	//glDrawArrays(GL_TRIANGLE_STRIP,0,4);
	glDrawElements(GL_TRIANGLE_STRIP, (GLsizei)(atl->n_of_quads * 6),GL_UNSIGNED_SHORT,0);

	glBindBuffer(GL_ARRAY_BUFFER,0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,0);
	*/


	glBindVertexArray(atl->vaoname);
	PRINT_DEBUG("draw %d quads\n",atl->n_of_quads);
	checkGLErrors("before render atlas");
	glDrawElements(GL_TRIANGLE_STRIP, (GLsizei)(atl->n_of_quads * 6),GL_UNSIGNED_SHORT,0);
  glBindVertexArray(0);
	checkGLErrors("after draw atals");
	kmGLPopMatrix();

}

void ml_atlas_render_byte(value * argv, int n) {
	ml_atlas_render(argv[0],argv[1],argv[2],argv[3],argv[4],argv[5],argv[6]);
}

void ml_atlas_clear(value atlas) {
	atlas_t *atl = ATLAS(atlas);
	glBindBuffer(GL_ARRAY_BUFFER,atl->buffersVBO[0]);
	glBufferSubData(GL_ARRAY_BUFFER,0,sizeof(lgTexQuad) * atl->n_of_quads,NULL);
	atl->n_of_quads = 0;
}
