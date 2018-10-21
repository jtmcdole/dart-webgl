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
 * Basic directional and abient lighting
 */
class Lesson7 extends Lesson {
  Cube cube;
  GlProgram program;
  Texture texture;

  bool get isLoaded => texture != false;

  Lesson7() {
    cube = new Cube();
    loadTexture('crate.gif', handleMipMapTexture).then((t) => texture = t);

    var attributes = ['aVertexPosition', 'aVertexNormal', 'aTextureCoord'];
    var uniforms = [
      'uPMatrix',
      'uMVMatrix',
      'uNMatrix',
      'uSampler',
      'uAmbientColor',
      'uLightingDirection',
      'uDirectionalColor',
      'uUseLighting'
    ];

    program = new GlProgram(
        '''
          precision mediump float;

          varying vec2 vTextureCoord;
          varying vec3 vLightWeighting;

          uniform sampler2D uSampler;

          void main(void) {
              vec4 textureColor = texture2D(uSampler, vec2(vTextureCoord.s, vTextureCoord.t));
              gl_FragColor = vec4(textureColor.rgb * vLightWeighting, textureColor.a);
          }
        ''',
        '''
          attribute vec3 aVertexPosition;
          attribute vec3 aVertexNormal;
          attribute vec2 aTextureCoord;

          uniform mat4 uMVMatrix;
          uniform mat4 uPMatrix;
          uniform mat3 uNMatrix;

          uniform vec3 uAmbientColor;

          uniform vec3 uLightingDirection;
          uniform vec3 uDirectionalColor;

          uniform bool uUseLighting;

          varying vec2 vTextureCoord;
          varying vec3 vLightWeighting;

          void main(void) {
              gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
              vTextureCoord = aTextureCoord;

              if (!uUseLighting) {
                  vLightWeighting = vec3(1.0, 1.0, 1.0);
              } else {
                  vec3 transformedNormal = uNMatrix * aVertexNormal;
                  float directionalLightWeighting = max(dot(transformedNormal, uLightingDirection), 0.0);
                  vLightWeighting = uAmbientColor + uDirectionalColor * directionalLightWeighting;
              }
          }
        ''',
        attributes,
        uniforms);

    gl.useProgram(program.program);
  }

  get uPMatrix => program.uniforms["uPMatrix"];
  get uMVMatrix => program.uniforms["uMVMatrix"];
  get uNMatrix => program.uniforms["uNMatrix"];
  get uSampler => program.uniforms["uSampler"];
  get uAmbientColor => program.uniforms["uAmbientColor"];
  get uLightingDirection => program.uniforms["uLightingDirection"];
  get uDirectionalColor => program.uniforms["uDirectionalColor"];
  get uUseLighting => program.uniforms["uUseLighting"];

  void setMatrixUniforms() {
    gl.uniformMatrix4fv(uPMatrix, false, pMatrix.buf);
    gl.uniformMatrix4fv(uMVMatrix, false, mvMatrix.buf);
    var normalMatrix = mvMatrix.toInverseMat3();
    normalMatrix.transposeSelf();
    gl.uniformMatrix3fv(uNMatrix, false, normalMatrix.buf);
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
      ..translate([0.0, 0.0, z])
      ..rotateX(radians(xRot))
      ..rotateY(radians(yRot));

    gl.uniform1i(uUseLighting, _lighting.checked ? 1 : 0);
    if (_lighting.checked) {
      gl.uniform3f(uAmbientColor, double.parse(_aR.value),
          double.parse(_aG.value), double.parse(_aB.value));

      // Take the lighting point and normalize / reverse it.
      Vector3 direction = new Vector3(double.parse(_ldX.value),
          double.parse(_ldY.value), double.parse(_ldZ.value));
      direction = direction.normalize().scale(-1.0);
      gl.uniform3fv(uLightingDirection, direction.buf);

      gl.uniform3f(uDirectionalColor, double.parse(_dR.value),
          double.parse(_dG.value), double.parse(_dB.value));
    }

    gl.activeTexture(WebGL.TEXTURE0);
    gl.bindTexture(WebGL.TEXTURE_2D, texture);
    gl.uniform1i(uSampler, 0);

    cube.draw(
        setUniforms: setMatrixUniforms,
        vertex: program.attributes['aVertexPosition'],
        coord: program.attributes['aTextureCoord'],
        normal: program.attributes['aVertexNormal']);

    mvPopMatrix();
  }

  num xSpeed = 3.0, ySpeed = -3.0;
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

  // Lighting enabled / Ambient color
  InputElement _lighting, _aR, _aG, _aB;

  // Light position
  InputElement _ldX, _ldY, _ldZ;

  // Directional light color
  InputElement _dR, _dG, _dB;

  void initHtml(DivElement hook) {
    hook.setInnerHtml(
        """
    <input type="checkbox" id="lighting" checked /> Use lighting<br/>
    (Use cursor keys to spin the box and <code>Page Up</code>/<code>Page Down</code> to zoom out/in)

    <br/>
    <h2>Directional light:</h2>

    <table style="border: 0; padding: 10px;">
        <tr>
            <td><b>Direction:</b>
            <td>X: <input type="text" id="lightDirectionX" value="-0.25" />
            <td>Y: <input type="text" id="lightDirectionY" value="-0.25" />
            <td>Z: <input type="text" id="lightDirectionZ" value="-1.0" />
        </tr>
        <tr>
            <td><b>Colour:</b>
            <td>R: <input type="text" id="directionalR" value="0.8" />
            <td>G: <input type="text" id="directionalG" value="0.8" />
            <td>B: <input type="text" id="directionalB" value="0.8" />
        </tr>
    </table>

    <h2>Ambient light:</h2>
    <table style="border: 0; padding: 10px;">
        <tr>
            <td><b>Colour:</b>
            <td>R: <input type="text" id="ambientR" value="0.2" />
            <td>G: <input type="text" id="ambientG" value="0.2" />
            <td>B: <input type="text" id="ambientB" value="0.2" />
        </tr>
    </table>
    """,
        treeSanitizer: new NullTreeSanitizer());

    // Re-look up our dom elements
    _lighting = querySelector("#lighting");
    _aR = querySelector("#ambientR");
    _aG = querySelector("#ambientG");
    _aB = querySelector("#ambientB");

    _dR = querySelector("#directionalR");
    _dG = querySelector("#directionalG");
    _dB = querySelector("#directionalB");

    _ldX = querySelector("#lightDirectionX");
    _ldY = querySelector("#lightDirectionY");
    _ldZ = querySelector("#lightDirectionZ");
  }
}
