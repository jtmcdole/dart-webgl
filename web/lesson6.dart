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
 * Textures part two: filtering.
 */
class Lesson6 extends Lesson {
  GlProgram program;
  List<Texture> textures = [];
  Cube cube;

  bool get isLoaded => textures.length == 3;

  Lesson6() {
    cube = new Cube();

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
        ''', attributes, uniforms);

    gl.useProgram(program.program);


    // Do some extra texture filters after loading the create texture
    loadTexture("crate.gif", (Texture text, ImageElement ele) {
      gl.pixelStorei(UNPACK_FLIP_Y_WEBGL, 1);
      textures.add(text);

      gl.bindTexture(TEXTURE_2D, textures[0]);
      gl.texImage2DImage(TEXTURE_2D, 0, RGBA, RGBA, UNSIGNED_BYTE, ele);
      gl.texParameteri(TEXTURE_2D, TEXTURE_MAG_FILTER, NEAREST);
      gl.texParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER, NEAREST);

      textures.add(gl.createTexture());
      gl.bindTexture(TEXTURE_2D, textures[1]);
      gl.texImage2DImage(TEXTURE_2D, 0, RGBA, RGBA, UNSIGNED_BYTE, ele);
      gl.texParameteri(TEXTURE_2D, TEXTURE_MAG_FILTER, LINEAR);
      gl.texParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER, LINEAR);

      textures.add(gl.createTexture());
      gl.bindTexture(TEXTURE_2D, textures[2]);
      gl.texImage2DImage(TEXTURE_2D, 0, RGBA, RGBA, UNSIGNED_BYTE, ele);
      gl.texParameteri(TEXTURE_2D, TEXTURE_MAG_FILTER, LINEAR);
      gl.texParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER, LINEAR_MIPMAP_NEAREST);
      gl.generateMipmap(TEXTURE_2D);

      // reset the texture 2d
      gl.bindTexture(TEXTURE_2D, null);
    });

    // We want to trigger on the unique key-down event for switching filters;
    // trying to handle this in handleKeys would lead to rapid changing.
    window.onKeyDown.listen((event) {
      if (event.keyCode == KeyCode.F) {
        activeFilter = (activeFilter + 1) % 3;
      }
    });
  }

  int activeFilter = 0;

  void drawScene(num viewWidth, num viewHeight, num aspect) {
    if (!isLoaded) return;
    // Basic viewport setup and clearing of the screen
    gl.viewport(0, 0, viewWidth, viewHeight);
    gl.clear(COLOR_BUFFER_BIT | DEPTH_BUFFER_BIT);
    gl.enable(DEPTH_TEST);
    gl.disable(BLEND);

    // Setup the perspective - you might be wondering why we do this every
    // time, and that will become clear in much later lessons. Just know, you
    // are not crazy for thinking of caching this.
    pMatrix = Matrix4.perspective(45.0, aspect, 0.1, 100.0);

    // First stash the current model view matrix before we start moving around.
    mvPushMatrix();

    mvMatrix..translate([0.0, 0.0, z])..
        rotateX(radians(xRot))..
        rotateY(radians(yRot));

    gl.activeTexture(TEXTURE0);
    gl.bindTexture(TEXTURE_2D, textures[activeFilter]);
    gl.uniform1i(uSampler, 0);
    cube.draw(setUniforms: setMatrixUniforms,
        vertex: program.attributes['aVertexPosition'],
        coord: program.attributes['aTextureCoord'] );

    // Finally, reset the matrix back to what it was before we moved around.
    mvPopMatrix();
  }

  get uPMatrix  => program.uniforms["uPMatrix"];
  get uMVMatrix  => program.uniforms["uMVMatrix"];
  get uSampler => program.uniforms["uSampler"];

  void setMatrixUniforms() {
    gl.uniformMatrix4fv(uPMatrix, false, pMatrix.buf);
    gl.uniformMatrix4fv(uMVMatrix, false, mvMatrix.buf);
  }

  num xSpeed = 0.0, ySpeed = 0.0;
  num xRot = 0.0, yRot = 0.0;
  num z = -5.0;

  void animate(num now) {
    if (lastTime != 0) {
      var elapsed = now - lastTime;

      xRot += (xSpeed * elapsed) / 1000.0;
      yRot += (ySpeed * elapsed) / 1000.0;
    }
    lastTime = now;
  }

  void handleKeys() {
    handleDirection(
        up: () => ySpeed -= 1.0,
        down: () => ySpeed += 1.0,
        left: () => xSpeed -= 1.0,
        right: () => xSpeed += 1.0);
    if (isActive(KeyCode.PAGE_UP)) {
      z -= 0.05;
    }
    if (isActive(KeyCode.PAGE_DOWN)) {
      z += 0.05;
    }
  }

  void initHtml(DivElement hook) {
    hook.innerHtml = """
    <h2>Controls:</h2>

    <ul>
        <li><code>Page Up</code>/<code>Page Down</code> to zoom out/in
        <li>Cursor keys: make the cube rotate (the longer you hold down a cursor key, the more it accelerates)
        <li><code>F</code> to toggle through three different kinds of texture filters
    </ul>
    """;
  }
}
