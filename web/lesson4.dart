// Copyright (c) 2013, John Thomas McDole.
/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
part of learn_gl;

/**
 * Draw a colored triangle and a square, and have them rotate on axis.
 * This lesson is nearly identical to Lesson 2, and we could clean it up...
 * however that's a future lesson.
 */
class Lesson4 extends Lesson {
  GlProgram program;

  Pyramid pyramid = new Pyramid();
  Cube cube = new Cube();

  num rPyramid = 0.0, rCube = 0.0;

  Lesson4() {
    program = new GlProgram(
        '''
          precision mediump float;

          varying vec4 vColor;

          void main(void) {
            gl_FragColor = vColor;
          }
        ''',
        '''
          attribute vec3 aVertexPosition;
          attribute vec4 aVertexColor;

          uniform mat4 uMVMatrix;
          uniform mat4 uPMatrix;

          varying vec4 vColor;

          void main(void) {
              gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
              vColor = aVertexColor;
          }
        ''',
        ['aVertexPosition', 'aVertexColor'],
        ['uMVMatrix', 'uPMatrix']);
    gl.useProgram(program.program);

    // Currently this is hardcoded, because well... everything else is textures
    // from here out.
    cube.addColor(new CubeColor());

    // Specify the color to clear with (black with 100% alpha) and then enable
    // depth testing.
    gl.clearColor(0.0, 0.0, 0.0, 1.0);
  }

  void drawScene(num viewWidth, num viewHeight, num aspect) {
    // Basic viewport setup and clearing of the screen
    gl.viewport(0, 0, viewWidth, viewHeight);
    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);

    gl.enable(WebGL.DEPTH_TEST);
    gl.disable(WebGL.BLEND);

    // Setup the perspective - you might be wondering why we do this every
    // time, and that will become clear in much later lessons. Just know, you
    // are not crazy for thinking of caching this.
    pMatrix = Matrix4.perspective(45.0, aspect, 0.1, 100.0);

    // First stash the current model view matrix before we start moving around.
    mvPushMatrix();

    mvMatrix.translate([-1.5, 0.0, -8.0]);

    // Let the user play around with some directional changes.
    mvMatrix.rotateX(radians(x))..rotateY(radians(y));

    mvPushMatrix();
    mvMatrix.rotate(radians(rPyramid), [0, 1, 0]);
    pyramid.draw(
        setUniforms: setMatrixUniforms,
        vertex: program.attributes['aVertexPosition'],
        color: program.attributes['aVertexColor']);
    mvPopMatrix();

    // Move 3 units to the right
    mvMatrix.translate([3.0, 0.0, 0.0]);
    mvMatrix.rotate(radians(rCube), [1, 1, 1]);
    cube.draw(
        setUniforms: setMatrixUniforms,
        vertex: program.attributes['aVertexPosition'],
        color: program.attributes['aVertexColor']);

    // Finally, reset the matrix back to what it was before we moved around.
    mvPopMatrix();
  }

  /**
   * Write the matrix uniforms (model view matrix and perspective matrix) so
   * WebGL knows what to do with them.
   */
  setMatrixUniforms() {
    gl.uniformMatrix4fv(program.uniforms['uPMatrix'], false, pMatrix.buf);
    gl.uniformMatrix4fv(program.uniforms['uMVMatrix'], false, mvMatrix.buf);
  }

  /**
   * Every time the browser tells us to draw the scene, animate is called.
   * If there's something being movied, this is where that movement i
   * calculated.
   */
  void animate(num now) {
    if (lastTime != 0) {
      var elapsed = now - lastTime;
      rPyramid += (90 * elapsed) / 1000.0;
      rCube -= (75 * elapsed) / 1000.0;
    }
    lastTime = now;
  }

  num x = 0.0, y = 0.0, z = 0.0;
  void handleKeys() {
    handleDirection(
        up: () => y -= 0.5,
        down: () => y += 0.5,
        left: () => x -= 0.5,
        right: () => x += 0.5);
  }
}
