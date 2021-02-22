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

/// Load a world!
class Lesson10 extends Lesson {
  late GlProgram program;
  Texture? texture;
  JsonObject? world;

  bool get isLoaded => world != null && texture != null;

  Lesson10() {
    JsonObject.fromUrl("world.json").then((object) {
      world = object;
      print("world loaded with ${world?._itemSize}");
    });

    loadTexture("mcdole.gif", (Texture texture, ImageElement ele) {
      gl.pixelStorei(WebGL.UNPACK_FLIP_Y_WEBGL, 1);
      gl.bindTexture(WebGL.TEXTURE_2D, texture);
      gl.texImage2D(
        WebGL.TEXTURE_2D,
        0,
        WebGL.RGBA,
        WebGL.RGBA,
        WebGL.UNSIGNED_BYTE,
        ele,
      );
      gl.texParameteri(
        WebGL.TEXTURE_2D,
        WebGL.TEXTURE_MAG_FILTER,
        WebGL.LINEAR,
      );
      gl.texParameteri(
        WebGL.TEXTURE_2D,
        WebGL.TEXTURE_MIN_FILTER,
        WebGL.LINEAR,
      );
      this.texture = texture;
      print("texture loaded");
    });

    var attributes = ['aVertexPosition', 'aTextureCoord'];
    var uniforms = ['uMVMatrix', 'uPMatrix', 'uSampler'];
    program = new GlProgram(
      """
          precision mediump float;

          varying vec2 vTextureCoord;

          uniform sampler2D uSampler;

          void main(void) {
              gl_FragColor = texture2D(uSampler, vec2(vTextureCoord.s, vTextureCoord.t));
          }
        """,
      """
          attribute vec3 aVertexPosition;
          attribute vec2 aTextureCoord;

          uniform mat4 uMVMatrix;
          uniform mat4 uPMatrix;

          varying vec2 vTextureCoord;

          void main(void) {
              gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
              vTextureCoord = aTextureCoord;
          }
        """,
      attributes,
      uniforms,
    );
    gl.useProgram(program.program);
  }

  get aTextureCoord => program.attributes['aTextureCoord'];
  get aVertexPosition => program.attributes['aVertexPosition'];

  get uSampler => program.uniforms["uSampler"];
  get uPMatrix => program.uniforms["uPMatrix"];
  get uMVMatrix => program.uniforms["uMVMatrix"];

  void drawScene(int viewWidth, int viewHeight, double aspect) {
    if (!isLoaded) return;

    gl.disable(WebGL.BLEND);
    gl.enable(WebGL.DEPTH_TEST);

    // Basic viewport setup and clearing of the screen
    gl.viewport(0, 0, viewWidth, viewHeight);
    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);

    // Setup the perspective - you might be wondering why we do this every
    // time, and that will become clear in much later lessons. Just know, you
    // are not crazy for thinking of caching this.
    pMatrix = Matrix4.perspective(45.0, aspect, 0.1, 100.0);

    mvPushMatrix();

    mvMatrix
      ..rotateX(radians(-pitch))
      ..rotateY(radians(-yaw))
      ..translate([-xPos, -yPos, -zPos]);

    gl.activeTexture(WebGL.TEXTURE0);
    gl.bindTexture(WebGL.TEXTURE_2D, texture);
    gl.uniform1i(uSampler, 0);

    world?.draw(
        vertex: aVertexPosition,
        coord: aTextureCoord,
        setUniforms: () {
          gl.uniformMatrix4fv(uPMatrix, false, pMatrix.buf);
          gl.uniformMatrix4fv(uMVMatrix, false, mvMatrix.buf);
        });

    mvPopMatrix();
  }

  double pitch = 0.0, yaw = 0.0;
  double pitchRate = 0.0, yawRate = 0.0;
  double xPos = 0.0, yPos = 0.4, zPos = 0.0;
  double speed = 0.0;

  void animate(double now) {
    if (lastTime != 0) {
      var elapsed = now - lastTime;

      if (speed != 0) {
        xPos -= sin(radians(yaw)) * speed * elapsed;
        zPos -= cos(radians(yaw)) * speed * elapsed;
      }
      yaw += yawRate * elapsed;
      pitch += pitchRate * elapsed;
    }
    lastTime = now;
  }

  void handleKeys() {
    if (anyActive([KeyCode.UP, KeyCode.W])) {
      speed = 0.003;
    } else if (anyActive([KeyCode.DOWN, KeyCode.S])) {
      speed = -0.003;
    } else {
      speed = 0.0;
    }
    if (anyActive([KeyCode.LEFT, KeyCode.A])) {
      yawRate = 0.1;
    } else if (anyActive([KeyCode.RIGHT, KeyCode.D])) {
      yawRate = -0.1;
    } else {
      yawRate = 0.0;
    }
    if (anyActive([KeyCode.PAGE_UP, KeyCode.NINE])) {
      pitchRate = 0.1;
    } else if (anyActive([KeyCode.PAGE_DOWN, KeyCode.THREE])) {
      pitchRate = -0.1;
    } else {
      pitchRate = 0.0;
    }
  }

  void initHtml(DivElement hook) {
    hook.setInnerHtml(
      """
    Use the cursor keys or WASD to run around, and <code>Page Up</code>/<code>Page Down</code> to
    look up and down.
    """,
      treeSanitizer: new NullTreeSanitizer(),
    );
  }
}
