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
 * Twinkle, twinkle little star...
 */
class Lesson9 extends Lesson {
  GlProgram program;
  Texture texture;
  List<Star> stars = [];

  bool get isLoaded => texture != null;

  Lesson9() {
    for (num i = 0; i < 50; i++) {
      stars.add(new Star((i / 50) * 5.0, i / 50));
    }
    loadTexture("star.gif", (Texture texture, ImageElement ele) {
      gl.pixelStorei(WebGL.UNPACK_FLIP_Y_WEBGL, 1);
      gl.bindTexture(WebGL.TEXTURE_2D, texture);
      gl.texImage2D(WebGL.TEXTURE_2D, 0, WebGL.RGBA, WebGL.RGBA, WebGL.UNSIGNED_BYTE, ele);
      gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MAG_FILTER, WebGL.LINEAR);
      gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MIN_FILTER, WebGL.LINEAR);

      gl.bindTexture(WebGL.TEXTURE_2D, null);
      this.texture = texture;
    });

    var attributes = ['aVertexPosition', 'aTextureCoord'];
    var uniforms = ['uMVMatrix', 'uPMatrix', 'uColor', 'uSampler'];
    program = new GlProgram(
        '''
          precision mediump float;

          varying vec2 vTextureCoord;

          uniform sampler2D uSampler;

          uniform vec3 uColor;

          void main(void) {
              vec4 textureColor = texture2D(uSampler, vec2(vTextureCoord.s, vTextureCoord.t));
              gl_FragColor = textureColor * vec4(uColor, 1.0);
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

    // Setup the perspective - you might be wondering why we do this every
    // time, and that will become clear in much later lessons. Just know, you
    // are not crazy for thinking of caching this.
    pMatrix = Matrix4.perspective(45.0, aspect, 0.1, 100.0);

    // First stash the current model view matrix before we start moving around.
    mvPushMatrix();
    gl.blendFunc(WebGL.SRC_ALPHA, WebGL.ONE);
    gl.disable(WebGL.DEPTH_TEST);
    gl.enable(WebGL.BLEND);

    mvMatrix
      ..translate([0.0, 0.0, zoom])
      ..rotateX(radians(tilt));

    gl.activeTexture(WebGL.TEXTURE0);
    gl.bindTexture(WebGL.TEXTURE_2D, texture);
    gl.uniform1i(program.uniforms['uSampler'], 0);

    for (Star star in stars) {
      star.draw(
          vertex: program.attributes['aVertexPosition'],
          coord: program.attributes['aTextureCoord'],
          color: program.uniforms['uColor'],
          twinkle: _twinkle.checked,
          tilt: tilt,
          spin: spin,
          setUniforms: setMatrixUniforms);
    }
    mvPopMatrix();
  }

  get uPMatrix => program.uniforms["uPMatrix"];
  get uMVMatrix => program.uniforms["uMVMatrix"];

  void setMatrixUniforms() {
    gl.uniformMatrix4fv(uPMatrix, false, pMatrix.buf);
    gl.uniformMatrix4fv(uMVMatrix, false, mvMatrix.buf);
  }

  num tilt = 90.0;
  num spin = 0.0;
  num zoom = -15.0;

  void animate(num now) {
    if (lastTime != 0) {
      var elapsed = now - lastTime;
      for (Star star in stars) {
        star.animate(elapsed);
      }
    }
    lastTime = now;
  }

  void handleKeys() {
    handleDirection(up: () => tilt += 2.0, down: () => tilt -= 2.0);
    if (isActive(KeyCode.PAGE_UP)) {
      zoom -= 0.1;
    }
    if (isActive(KeyCode.PAGE_DOWN)) {
      zoom += 0.1;
    }
  }

  InputElement _twinkle;
  initHtml(DivElement hook) {
    hook.setInnerHtml(
        '''
    <input type="checkbox" id="twinkle" /> Twinkle<br/>
    (Use up/down cursor keys to rotate, and <code>Page Up</code>/<code>Page Down</code> to zoom out/in)
    ''',
        treeSanitizer: new NullTreeSanitizer());

    _twinkle = querySelector("#twinkle");
  }
}
