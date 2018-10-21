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
 * Spheres, rotations matricies, and mouse events
 */
class Lesson11 extends Lesson {
  GlProgram program;
  Sphere moon;
  Texture moonTexture;

  Matrix4 _rotation = new Matrix4()..identity();
  bool _mouseDown = false;
  var _lastMouseX, _lastMouseY;

  bool get isLoaded => moonTexture != null;

  Lesson11() {
    moon = new Sphere(lats: 30, lons: 30, radius: 2);

    var attributes = ['aVertexPosition', 'aVertexNormal', 'aTextureCoord'];
    var uniforms = [
      'uSampler',
      'uMVMatrix',
      'uPMatrix',
      'uNMatrix',
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

    loadTexture("moon.bmp", handleMipMapTexture).then((t) => moonTexture = t);

    gl.useProgram(program.program);

    // Mouse handling (extra listeners)
    canvas.onMouseDown.listen((MouseEvent event) {
      _mouseDown = true;
      _lastMouseX = event.client.x;
      _lastMouseY = event.client.y;
    });

    document.onMouseUp.listen((MouseEvent event) {
      _mouseDown = false;
    });

    document.onMouseMove.listen((MouseEvent event) {
      if (!_mouseDown) return;
      var newX = event.client.x;
      var newY = event.client.y;
      var deltaX = newX - _lastMouseX;
      Matrix4 newRot = new Matrix4()
        ..identity()
        ..rotateY(radians(deltaX / 10));
      var deltaY = newY - _lastMouseY;
      newRot.rotateX(radians(deltaY / 10));
      _rotation = newRot * _rotation; // C = A * B, first operand = newRot.
      _lastMouseX = newX;
      _lastMouseY = newY;
    });
  }

  get aVertexPosition => program.attributes['aVertexPosition'];
  get aVertexNormal => program.attributes['aVertexNormal'];
  get aTextureCoord => program.attributes['aTextureCoord'];

  get uSampler => program.uniforms['uSampler'];
  get uMVMatrix => program.uniforms['uMVMatrix'];
  get uPMatrix => program.uniforms['uPMatrix'];
  get uNMatrix => program.uniforms['uNMatrix'];
  get uAmbientColor => program.uniforms['uAmbientColor'];
  get uLightingDirection => program.uniforms['uLightingDirection'];
  get uDirectionalColor => program.uniforms['uDirectionalColor'];
  get uUseLighting => program.uniforms['uUseLighting'];

  void drawScene(num viewWidth, num viewHeight, num aspect) {
    if (!isLoaded) return;

    gl.viewport(0, 0, viewWidth, viewHeight);
    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);
    gl.enable(WebGL.DEPTH_TEST);
    gl.disable(WebGL.BLEND);

    pMatrix = Matrix4.perspective(45.0, aspect, 0.1, 100.0);

    // One: setup lighting information
    bool lighting = _lighting.checked;
    gl.uniform1i(uUseLighting, lighting ? 1 : 0);
    if (lighting) {
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

    mvPushMatrix();
    // Setup the scene -20.0 away.
    mvMatrix = mvMatrix..translate([0.0, 0.0, -7.0]);
    mvMatrix = mvMatrix * _rotation;

    gl.activeTexture(WebGL.TEXTURE0);
    gl.bindTexture(WebGL.TEXTURE_2D, moonTexture);
    gl.uniform1i(uSampler, 0);
    moon.draw(
        vertex: aVertexPosition,
        normal: aVertexNormal,
        coord: aTextureCoord,
        setUniforms: setMatrixUniforms);
    mvPopMatrix();
  }

  var mouseDown = false;
  var lastMouseX = null;
  var lastMouseY = null;
  void setMatrixUniforms() {
    gl.uniformMatrix4fv(uPMatrix, false, pMatrix.buf);
    gl.uniformMatrix4fv(uMVMatrix, false, mvMatrix.buf);
    var normalMatrix = mvMatrix.toInverseMat3();
    normalMatrix.transposeSelf();
    gl.uniformMatrix3fv(uNMatrix, false, normalMatrix.buf);
  }

  void animate(num now) {}

  void handleKeys() {}

  // Lighting enabled / Ambient color
  InputElement _lighting, _aR, _aG, _aB;

  // Light position
  InputElement _ldX, _ldY, _ldZ;

  // Point color
  InputElement _dR, _dG, _dB;

  void initHtml(DivElement hook) {
    hook.setInnerHtml(
        """"
    <input type="checkbox" id="lighting" checked /> Use lighting<br/>
    Spin the moon by dragging it with the mouse.
    <br/>

    <h2>Directional light:</h2>

    <table style="border: 0; padding: 10px;">
        <tr>
            <td><b>Direction:</b>
            <td>X: <input type="text" id="lightDirectionX" value="-1.0" />
            <td>Y: <input type="text" id="lightDirectionY" value="-1.0" />
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
    <br/>

    Moon texture courtesy of <a href="http://maps.jpl.nasa.gov/">the Jet Propulsion Laboratory</a>.
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
