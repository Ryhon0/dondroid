module main;

/*
 * Copyright (C) 2010 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

import _engine;
import log;

import core.stdc.stdlib : malloc;
import core.stdc.string : memset;

import EGL.eglplatform : EGLint;
import EGL.egl, GLES.gl;

import android.input, android.looper : ALooper_pollAll;
import android.native_window : ANativeWindow_setBuffersGeometry;
import android.sensor, android.log, android_native_app_glue;

void main(){}
/**
 * This is the main entry point of a native application that is using
 * android_native_app_glue.  It runs in its own thread, with its own
 * event loop for receiving input events and doing other things.
 */
extern (C) void android_main(android_app* state) {
    engine engine;

    // Make sure glue isn't stripped.
    app_dummy();

    memset(&engine, 0, engine.sizeof);
    state.userData = &engine;
    state.onAppCmd = &engine_handle_cmd;
    state.onInputEvent = &engine_handle_input;
    engine.app = state;

    // Prepare to monitor accelerometer
    engine.sensorManager = ASensorManager_getInstance();
    engine.accelerometerSensor = ASensorManager_getDefaultSensor(engine.sensorManager,
            ASENSOR_TYPE_ACCELEROMETER);
    engine.sensorEventQueue = ASensorManager_createEventQueue(engine.sensorManager,
            state.looper, LOOPER_ID_USER, null, null);

    if (state.savedState != null) {
        // We are starting with a previous saved state; restore from it.
        engine.state = *cast(saved_state*)state.savedState;
    }

    // loop waiting for stuff to do.

    while (1) {
        // Read all pending events.
        int ident;
        int events;
        android_poll_source* source;

        // If not animating, we will block forever waiting for events.
        // If animating, we loop until all events are read, then continue
        // to draw the next frame of animation.
        while ((ident=ALooper_pollAll(engine.animating ? 0 : -1, null, &events,
                cast(void**)&source)) >= 0) {

            // Process this event.
            if (source != null) {
                source.process(state, source);
            }

            // If a sensor has data, process it now.
            if (ident == LOOPER_ID_USER) {
                if (engine.accelerometerSensor != null) {
                    ASensorEvent event;
                    while (ASensorEventQueue_getEvents(engine.sensorEventQueue,
                            &event, 1) > 0) {
                        LOGI("accelerometer: x=%f y=%f z=%f",
                                event.acceleration.x, event.acceleration.y,
                                event.acceleration.z);
						ax = event.acceleration.x;
						ay = event.acceleration.y;
						az = event.acceleration.z;
                    }
                }
            }

            // Check if we are exiting.
            if (state.destroyRequested != 0) {
                engine_term_display(&engine);
                return;
            }
        }

        if (engine.animating) {
            // Done with events; draw next animation frame.
            engine.state.angle += .01f;
            if (engine.state.angle > 1) {
                engine.state.angle = 0;
            }

            // Drawing is throttled to the screen update rate, so there
            // is no need to do timing here.
            engine_draw_frame(&engine);
        }
    }
}
