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
 * Handle custome shaders, animation, etc for Lesson 12 - Point Lighting.
 * In this lesson, we spin a sphere and a cube around a central axis with at its core is a
 * point of directional lighting.
 *
 * In the original lesson, the moon and box are tidal locked (always showing the same face),
 * lets play around with that.
 */
class Lesson12 extends Lesson {
  GlProgram program;
  Cube cube;
  Sphere moon;
  Texture moonTexture, cubeTexture;

  bool get isLoaded => moonTexture != null && cubeTexture != null;

  Lesson12() {
    moon = new Sphere(lats: 30, lons: 30, radius: 2);
    cube = new Cube();

    var attributes = ['aVertexPosition', 'aVertexNormal', 'aTextureCoord'];
    var uniforms = [
      'uSampler',
      'uMVMatrix',
      'uPMatrix',
      'uNMatrix',
      'uAmbientColor',
      'uPointLightingLocation',
      'uPointLightingColor',
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

          uniform vec3 uPointLightingLocation;
          uniform vec3 uPointLightingColor;

          uniform bool uUseLighting;

          varying vec2 vTextureCoord;
          varying vec3 vLightWeighting;

          void main(void) {
              vec4 mvPosition = uMVMatrix * vec4(aVertexPosition, 1.0);
              gl_Position = uPMatrix * mvPosition;
              vTextureCoord = aTextureCoord;

              if (!uUseLighting) {
                  vLightWeighting = vec3(1.0, 1.0, 1.0);
              } else {
                  vec3 lightDirection = normalize(uPointLightingLocation - mvPosition.xyz);

                  vec3 transformedNormal = uNMatrix * aVertexNormal;
                  float directionalLightWeighting = max(dot(transformedNormal, lightDirection), 0.0);
                  vLightWeighting = uAmbientColor + uPointLightingColor * directionalLightWeighting;
              }
          }
        ''',
        attributes,
        uniforms);

    loadTexture("moon.bmp", handleMipMapTexture).then((t) => moonTexture = t);
    loadTexture("crate.gif", handleMipMapTexture).then((t) => cubeTexture = t);

    gl.useProgram(program.program);
    gl.enable(WebGL.DEPTH_TEST);
  }

  get aVertexPosition => program.attributes['aVertexPosition'];
  get aVertexNormal => program.attributes['aVertexNormal'];
  get aTextureCoord => program.attributes['aTextureCoord'];

  get uSampler => program.uniforms['uSampler'];
  get uMVMatrix => program.uniforms['uMVMatrix'];
  get uPMatrix => program.uniforms['uPMatrix'];
  get uNMatrix => program.uniforms['uNMatrix'];
  get uAmbientColor => program.uniforms['uAmbientColor'];
  get uPointLightingLocation => program.uniforms['uPointLightingLocation'];
  get uPointLightingColor => program.uniforms['uPointLightingColor'];
  get uUseLighting => program.uniforms['uUseLighting'];

  void drawScene(num viewWidth, num viewHeight, num aspect) {
    if (!isLoaded) return;

    gl.enable(WebGL.DEPTH_TEST);
    gl.disable(WebGL.BLEND);

    gl.viewport(0, 0, viewWidth, viewHeight);
    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);
    pMatrix = Matrix4.perspective(45.0, aspect, 0.1, 100.0);

    gl.useProgram(program.program);

    // One: setup lighting information
    bool lighting = _lighting.checked;
    gl.uniform1i(uUseLighting, lighting ? 1 : 0);
    if (lighting) {
      gl.uniform3f(uAmbientColor, double.parse(_aR.value),
          double.parse(_aG.value), double.parse(_aB.value));

      gl.uniform3f(uPointLightingLocation, double.parse(_lpX.value),
          double.parse(_lpY.value), double.parse(_lpZ.value));

      gl.uniform3f(uPointLightingColor, double.parse(_pR.value),
          double.parse(_pG.value), double.parse(_pB.value));
    }

    mvPushMatrix();

    // Setup the scene -20.0 away.
    mvMatrix
      ..translate([0.0, 0.0, -20.0])
      ..rotateX(radians(tilt));

    mvPushMatrix();
    // Rotate and move away from the scene
    mvMatrix
      ..rotateY(radians(moonAngle))
      ..translate([5.0, 0.0, 0.0]);
    gl.activeTexture(WebGL.TEXTURE0);
    gl.bindTexture(WebGL.TEXTURE_2D, moonTexture);
    gl.uniform1i(uSampler, 0);
    moon.draw(
        vertex: aVertexPosition,
        normal: aVertexNormal,
        coord: aTextureCoord,
        setUniforms: setMatrixUniforms);
    mvPopMatrix();

    mvMatrix
      ..rotateY(radians(cubeAngle))
      ..translate([5.0, 0.0, 0.0]);
    gl.activeTexture(WebGL.TEXTURE0);
    gl.bindTexture(WebGL.TEXTURE_2D, cubeTexture);
    gl.uniform1i(uSampler, 0);
    cube.draw(
        vertex: aVertexPosition,
        normal: aVertexNormal,
        coord: aTextureCoord,
        setUniforms: setMatrixUniforms);
    mvPopMatrix();
  }

  double moonAngle = 180.0;
  double cubeAngle = 0.0;
  double tilt = 0.0;

  void setMatrixUniforms() {
    gl.uniformMatrix4fv(uPMatrix, false, pMatrix.buf);
    gl.uniformMatrix4fv(uMVMatrix, false, mvMatrix.buf);
    var normalMatrix = mvMatrix.toInverseMat3();
    normalMatrix.transposeSelf();
    gl.uniformMatrix3fv(uNMatrix, false, normalMatrix.buf);
  }

  void animate(num now) {
    if (lastTime != 0) {
      var elapsed = now - lastTime;
      moonAngle += 0.05 * elapsed;
      cubeAngle += 0.05 * elapsed;
    }
    lastTime = now;
  }

  void handleKeys() {
    handleDirection(
        up: () => tilt -= 1.0,
        down: () => tilt += 1.0,
        left: () {
          moonAngle -= 1.0;
          cubeAngle -= 1.0;
        },
        right: () {
          moonAngle += 1.0;
          cubeAngle += 1.0;
        });
  }

  // Lighting enabled / Ambient color
  InputElement _lighting, _aR, _aG, _aB;

  // Light position
  InputElement _lpX, _lpY, _lpZ;

  // Point color
  InputElement _pR, _pG, _pB;

  void initHtml(DivElement hook) {
    hook.setInnerHtml(
        """
    <input type="checkbox" id="lighting" checked /> Use lighting<br/>
    <br/>

    <h2>Point light:</h2>

    <table style="border: 0; padding: 10px;">
        <tr>
            <td><b>Location:</b>
            <td>X: <input type="text" id="lightPositionX" value="0.0" />
            <td>Y: <input type="text" id="lightPositionY" value="0.0" />
            <td>Z: <input type="text" id="lightPositionZ" value="-20.0" />
        </tr>
        <tr>
            <td><b>Colour:</b>
            <td>R: <input type="text" id="pointR" value="0.8" />
            <td>G: <input type="text" id="pointG" value="0.8" />
            <td>B: <input type="text" id="pointB" value="0.8" />
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

    _pR = querySelector("#pointR");
    _pG = querySelector("#pointG");
    _pB = querySelector("#pointB");

    _lpX = querySelector("#lightPositionX");
    _lpY = querySelector("#lightPositionY");
    _lpZ = querySelector("#lightPositionZ");
  }
}
