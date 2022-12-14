module _engine;

import log;

import core.stdc.stdlib : malloc;
import core.stdc.string : memset;

import EGL.eglplatform : EGLint;
import EGL.egl, GLES.gl;

import android.input, android.looper : ALooper_pollAll;
import android.native_window : ANativeWindow_setBuffersGeometry;
import android.sensor, android.log, android_native_app_glue;

/**
 * Our saved state data.
 */
struct saved_state {
    float angle;
    float x;
    float y;
}

/**
 * Shared state for our app.
 */
struct engine {
    android_app* app;

    ASensorManager* sensorManager;
    const(ASensor)* accelerometerSensor;
    ASensorEventQueue* sensorEventQueue;

    int animating = 1;
    EGLDisplay display;
    EGLSurface surface;
    EGLContext context;
    int width;
    int height;
    saved_state state;
}


/**
 * Initialize an EGL context for the current display.
 */
int engine_init_display(engine* engine) {
    // initialize OpenGL ES and EGL

    /*
     * Here specify the attributes of the desired configuration.
     * Below, we select an EGLConfig with at least 8 bits per color
     * component compatible with on-screen windows
     */
    const(EGLint)[9] attribs = [
            EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
            EGL_BLUE_SIZE, 8,
            EGL_GREEN_SIZE, 8,
            EGL_RED_SIZE, 8,
            EGL_NONE
    ];
    EGLint w, h, dummy, format;
    EGLint numConfigs;
    EGLConfig config;
    EGLSurface surface;
    EGLContext context;

    EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);

    eglInitialize(display, null, null);

    /* Here, the application chooses the configuration it desires. In this
     * sample, we have a very simplified selection process, where we pick
     * the first EGLConfig that matches our criteria */
    eglChooseConfig(display, attribs.ptr, &config, 1, &numConfigs);

    /* EGL_NATIVE_VISUAL_ID is an attribute of the EGLConfig that is
     * guaranteed to be accepted by ANativeWindow_setBuffersGeometry().
     * As soon as we picked a EGLConfig, we can safely reconfigure the
     * ANativeWindow buffers to match, using EGL_NATIVE_VISUAL_ID. */
    eglGetConfigAttrib(display, config, EGL_NATIVE_VISUAL_ID, &format);

    ANativeWindow_setBuffersGeometry(engine.app.window, 0, 0, format);

    surface = eglCreateWindowSurface(display, config, engine.app.window, null);
    context = eglCreateContext(display, config, null, null);

    if (eglMakeCurrent(display, surface, surface, context) == EGL_FALSE) {
        LOGW("Unable to eglMakeCurrent");
        return -1;
    }

    eglQuerySurface(display, surface, EGL_WIDTH, &w);
    eglQuerySurface(display, surface, EGL_HEIGHT, &h);

    engine.display = display;
    engine.context = context;
    engine.surface = surface;
    engine.width = w;
    engine.height = h;
    engine.state.angle = 0;

    // Initialize GL state.
    glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_FASTEST);
    glEnable(GL_CULL_FACE);
    glShadeModel(GL_SMOOTH);
    glDisable(GL_DEPTH_TEST);

    return 0;
}

float ax, ay, az;
/**
 * Just the current frame in the display.
 */
void engine_draw_frame(engine* engine) {
    if (engine.display == null) {
        // No display.
        return;
    }

    // Just fill the screen with a color.
    glClearColor(ax / 10, ay / 10, az /10, 1);
    glClear(GL_COLOR_BUFFER_BIT);

    eglSwapBuffers(engine.display, engine.surface);
}

/**
 * Tear down the EGL context currently associated with the display.
 */
void engine_term_display(engine* engine) {
    if (engine.display != EGL_NO_DISPLAY) {
        eglMakeCurrent(engine.display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        if (engine.context != EGL_NO_CONTEXT) {
            eglDestroyContext(engine.display, engine.context);
        }
        if (engine.surface != EGL_NO_SURFACE) {
            eglDestroySurface(engine.display, engine.surface);
        }
        eglTerminate(engine.display);
    }
    engine.animating = 0;
    engine.display = EGL_NO_DISPLAY;
    engine.context = EGL_NO_CONTEXT;
    engine.surface = EGL_NO_SURFACE;
}

/**
 * Process the next input event.
 */
int engine_handle_input(android_app* app, AInputEvent* event) {
    engine* engine = cast(engine*)app.userData;
    if (AInputEvent_getType(event) == AINPUT_EVENT_TYPE_MOTION) {
        engine.animating = 1;
        engine.state.x = AMotionEvent_getX(event, 0);
        engine.state.y = AMotionEvent_getY(event, 0);
        return 1;
    }
    return 0;
}

/**
 * Process the next main command.
 */
void engine_handle_cmd(android_app* app, int cmd) {
    engine* engine = cast(engine*)app.userData;
    switch (cmd) {
        case APP_CMD_SAVE_STATE:
            // The system has asked us to save our current state.  Do so.
            engine.app.savedState = malloc(saved_state.sizeof);
            *(cast(saved_state*)engine.app.savedState) = engine.state;
            engine.app.savedStateSize = saved_state.sizeof;
            break;
        case APP_CMD_INIT_WINDOW:
            // The window is being shown, get it ready.
            if (engine.app.window != null) {
                engine_init_display(engine);
                engine_draw_frame(engine);
            }
            break;
        case APP_CMD_TERM_WINDOW:
            // The window is being hidden or closed, clean it up.
            engine_term_display(engine);
            break;
        case APP_CMD_GAINED_FOCUS:
            // When our app gains focus, we start monitoring the accelerometer.
            if (engine.accelerometerSensor != null) {
                ASensorEventQueue_enableSensor(engine.sensorEventQueue,
                        engine.accelerometerSensor);
                // We'd like to get 60 events per second (in us).
                ASensorEventQueue_setEventRate(engine.sensorEventQueue,
                        engine.accelerometerSensor, (1000L/60)*1000);
            }
            engine.animating = 1;
            break;
        case APP_CMD_LOST_FOCUS:
            // When our app loses focus, we stop monitoring the accelerometer.
            // This is to avoid consuming battery while not being used.
            if (engine.accelerometerSensor != null) {
                ASensorEventQueue_disableSensor(engine.sensorEventQueue,
                        engine.accelerometerSensor);
            }
            // Also stop animating.
            engine.animating = 0;
            engine_draw_frame(engine);
            break;
        default:
            break;
    }
}