
#include <GL/glut.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/callback.h>
#include <caml/threads.h>


void ml_glutInit() { // FIXME: argc argv надо по идее 
	char *argv[] = {"glut",NULL};
	int argc = 1;
	glutInit(&argc,argv);
}

void ml_glutInitWindowSize(value width,value height) {
	glutInitWindowSize(Long_val(width),Long_val(height));
}
void ml_glutInitDisplayMode(value modes) { // FIXME: mode list
	value c;
	int flags = 0;
	while (modes != Val_unit) {
		c = Field(modes,0);
		switch (Long_val(c)) {
			case 0: flags |= GLUT_RGB; break;
			case 1: flags |= GLUT_RGBA; break;
			case 2: flags |= GLUT_INDEX; break;
			case 3: flags |= GLUT_SINGLE; break;
			case 4: flags |= GLUT_DOUBLE; break;
			case 5: flags |= GLUT_ACCUM; break;
			case 6: flags |= GLUT_ALPHA; break;
			case 7: flags |= GLUT_DEPTH; break;
			case 8: flags |= GLUT_STENCIL; break;
			case 9: flags |= GLUT_MULTISAMPLE; break;
			case 10: flags |= GLUT_STEREO; break;
			case 11: flags |= GLUT_LUMINANCE; break;
			default: caml_failwith("incorrect glutInitDisplayMode");
		};
		modes = Field(modes,1);
	};
	glutInitDisplayMode ( flags);
};


void ml_glutCreateWindow(value title) {
	glutCreateWindow(String_val(title));
}


static value displayFunc = 0;

void on_display(void) {
	caml_callback(displayFunc,Val_unit);
}

void ml_glutDisplayFunc(value display) {
	if (!displayFunc) {
		caml_register_global_root(&displayFunc);
	};
	displayFunc = display;
	glutDisplayFunc(on_display);
}


static value mouseFunc = 0;
void on_mouse(int button, int state, int x, int y) {
	value b;
	switch (button) {
		case GLUT_LEFT_BUTTON: b = Val_int(0);break;
		case GLUT_RIGHT_BUTTON: b = Val_int(1);break;
		case GLUT_MIDDLE_BUTTON: b = Val_int(2);break;
		default: caml_failwith("unknown button");
	};
	value s;
	switch (state) {
		case GLUT_DOWN: s = Val_int(0);break;
		case GLUT_UP: s = Val_int(1);break;
		default:caml_failwith("unknown state");
	};
	value m = caml_alloc_tuple(4);
	Field(m,0) = b;
	Field(m,1) = s;
	Field(m,2) = Val_long(x);
	Field(m,3) = Val_long(y);
	caml_callback(mouseFunc,m);
}

void ml_glutMouseFunc(value mouse) {
	if (!mouseFunc) caml_register_global_root(&mouseFunc);
	mouseFunc = mouse;
	glutMouseFunc(on_mouse);
}


static value motionFunc = 0;
void on_motion(int x, int y) {
	caml_callback2(motionFunc,Val_long(x),Val_long(y));
}

void ml_glutMotionFunc(value motion) {
	if (!motionFunc) caml_register_global_root(&motionFunc);
	motionFunc = motion;
	glutMotionFunc(on_motion);
}

static value idleFunc = 0;

void on_idle(void) {
	caml_callback(idleFunc,Val_unit);
}

void ml_glutIdleFunc(value idle) {
	glutIdleFunc (on_idle);
}


void ml_glutPostRedisplay(void) {
	glutPostRedisplay();
}

void ml_glutSwapBuffers(void) {
	glutSwapBuffers();
}

void ml_glutMainLoop(value param) {
	glutMainLoop ();
};