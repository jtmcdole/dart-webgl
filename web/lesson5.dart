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
 * Introducing Textures!
 */
class Lesson5 extends Lesson {
  GlProgram program;
  Texture neheTexture;
  Cube cube;

  bool get isLoaded => neheTexture != null;

  Lesson5() {
    cube = new Cube();
    loadTexture("nehe.gif", (Texture texture, ImageElement element) {
      gl.bindTexture(WebGL.TEXTURE_2D, texture);
      gl.pixelStorei(WebGL.UNPACK_FLIP_Y_WEBGL, 1);
      gl.texImage2D(WebGL.TEXTURE_2D, 0, WebGL.RGBA, WebGL.RGBA, WebGL.UNSIGNED_BYTE, element);
      gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MAG_FILTER, WebGL.NEAREST);
      gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MIN_FILTER, WebGL.NEAREST);
      gl.bindTexture(WebGL.TEXTURE_2D, null);
      neheTexture = texture;
    });

    var attributes = ['aVertexPosition', 'aTextureCoord'];
    var uniforms = ['uPMatrix', 'uMVMatrix', 'uSampler'];

    program = new GlProgram(
        '''
          precision mediump float;

          varying vec2 vTextureCoord;

          uniform sampler2D uSampler;

          void main(void) {
              gl_FragColor = texture2D(uSampler, vec2(vTextureCoord.s, vTextureCoord.t));
          }
        ''',
        '''
          attribute vec3 aVertexPosition;
          attribute vec2 aTextureCoord;

          uniform mat4 uMVMatrix;
          uniform mat4 uPMatrix;

          varying vec2 vTextureCoord;

          void main(void) {
              gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
              vTextureCoord = aTextureCoord;
          }
        ''',
        attributes,
        uniforms);

    gl.useProgram(program.program);
  }

  void drawScene(num viewWidth, num viewHeight, num aspect) {
    if (!isLoaded) return;

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

    mvMatrix
      ..translate([0.0, 0.0, -5.0])
      ..rotateX(radians(xRot))
      ..rotateY(radians(yRot))
      ..rotateZ(radians(zRot));

    gl.activeTexture(WebGL.TEXTURE0);
    gl.bindTexture(WebGL.TEXTURE_2D, neheTexture);
    gl.uniform1i(uSampler, 0);
    cube.draw(
        setUniforms: setMatrixUniforms,
        vertex: program.attributes['aVertexPosition'],
        coord: program.attributes['aTextureCoord']);

    // Finally, reset the matrix back to what it was before we moved around.
    mvPopMatrix();
  }

  get uPMatrix => program.uniforms["uPMatrix"];
  get uMVMatrix => program.uniforms["uMVMatrix"];
  get uSampler => program.uniforms["uSampler"];

  void setMatrixUniforms() {
    gl.uniformMatrix4fv(uPMatrix, false, pMatrix.buf);
    gl.uniformMatrix4fv(uMVMatrix, false, mvMatrix.buf);
  }

  num xRot = 0.0, yRot = 0.0, zRot = 0.0;

  void animate(num now) {
    if (lastTime != 0) {
      var elapsed = now - lastTime;

      xRot += (90 * elapsed) / 1000.0;
      yRot += (90 * elapsed) / 1000.0;
      zRot += (90 * elapsed) / 1000.0;
    }
    lastTime = now;
  }

  void handleKeys() {
    handleDirection(
        up: () => yRot -= 0.5,
        down: () => yRot += 0.5,
        left: () => xRot -= 0.5,
        right: () => xRot += 0.5);
  }
}
