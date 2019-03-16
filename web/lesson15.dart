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

class Lesson15 extends Lesson {
  GlProgram currentProgram;
  Sphere sphere;
  Texture earthTexture, moonTexture, earthSpecularMapTexture;

  int textureCount = 0;
  bool get isLoaded => sphere != null && textureCount == 3;

  double sphereAngle = 180.0;
  double tilt = 23.4;

  Lesson15() {
    sphere = new Sphere(lats: 30, lons: 30, radius: 13);

    var attributes = ['aVertexPosition', 'aVertexNormal', 'aTextureCoord'];
    var uniforms = [
      'uPMatrix',
      'uMVMatrix',
      'uNMatrix',
      'uAmbientColor',
      'uPointLightingLocation',
      'uPointLightingSpecularColor',
      'uPointLightingDiffuseColor',
      'uUseColorMap',
      'uUseSpecularMap',
      'uUseLighting',
      'uColorMapSampler',
      'uSpecularMapSampler'
    ];

    currentProgram = new GlProgram(
        '''
          precision mediump float;
      
          varying vec2 vTextureCoord;
          varying vec3 vTransformedNormal;
          varying vec4 vPosition;
      
          uniform bool uUseColorMap;
          uniform bool uUseSpecularMap;
          uniform bool uUseLighting;
      
          uniform vec3 uAmbientColor;
      
          uniform vec3 uPointLightingLocation;
          uniform vec3 uPointLightingSpecularColor;
          uniform vec3 uPointLightingDiffuseColor;
      
          uniform sampler2D uColorMapSampler;
          uniform sampler2D uSpecularMapSampler;
      
      
          void main(void) {
              vec3 lightWeighting;
              if (!uUseLighting) {
                  lightWeighting = vec3(1.0, 1.0, 1.0);
              } else {
                  vec3 lightDirection = normalize(uPointLightingLocation - vPosition.xyz);
                  vec3 normal = normalize(vTransformedNormal);
      
                  float specularLightWeighting = 0.0;
                  float shininess = 32.0;
                  if (uUseSpecularMap) {
                      shininess = texture2D(uSpecularMapSampler, vec2(vTextureCoord.s, vTextureCoord.t)).r * 255.0;
                  }
                  if (shininess < 255.0) {
                      vec3 eyeDirection = normalize(-vPosition.xyz);
                      vec3 reflectionDirection = reflect(-lightDirection, normal);
      
                      specularLightWeighting = pow(max(dot(reflectionDirection, eyeDirection), 0.0), shininess);
                  }
      
                  float diffuseLightWeighting = max(dot(normal, lightDirection), 0.0);
                  lightWeighting = uAmbientColor
                      + uPointLightingSpecularColor * specularLightWeighting
                      + uPointLightingDiffuseColor * diffuseLightWeighting;
              }
      
              vec4 fragmentColor;
              if (uUseColorMap) {
                  fragmentColor = texture2D(uColorMapSampler, vec2(vTextureCoord.s, vTextureCoord.t));
              } else {
                  fragmentColor = vec4(1.0, 1.0, 1.0, 1.0);
              }
              gl_FragColor = vec4(fragmentColor.rgb * lightWeighting, fragmentColor.a);
          }
        ''',
        '''
          attribute vec3 aVertexPosition;
          attribute vec3 aVertexNormal;
          attribute vec2 aTextureCoord;
      
          uniform mat4 uMVMatrix;
          uniform mat4 uPMatrix;
          uniform mat3 uNMatrix;
      
          varying vec2 vTextureCoord;
          varying vec3 vTransformedNormal;
          varying vec4 vPosition;
      
      
          void main(void) {
              vPosition = uMVMatrix * vec4(aVertexPosition, 1.0);
              gl_Position = uPMatrix * vPosition;
              vTextureCoord = aTextureCoord;
              vTransformedNormal = uNMatrix * aVertexNormal;
          }
        ''',
        attributes,
        uniforms);

    gl.useProgram(currentProgram.program);

    // Handle textures
    loadTexture("earth.jpg", handleMipMapTexture).then((t) {
      earthTexture = t;
      textureCount++;
    });
    loadTexture("moon.bmp", handleMipMapTexture).then((t) {
      moonTexture = t;
      textureCount++;
    });
    loadTexture("earth-specular.gif", handleMipMapTexture).then((t) {
      earthSpecularMapTexture = t;
      textureCount++;
    });

    gl.enable(WebGL.DEPTH_TEST);
  }

  get aVertexPosition => currentProgram.attributes["aVertexPosition"];
  get aVertexNormal => currentProgram.attributes["aVertexNormal"];
  get aTextureCoord => currentProgram.attributes["aTextureCoord"];

  get uPMatrix => currentProgram.uniforms["uPMatrix"];
  get uMVMatrix => currentProgram.uniforms["uMVMatrix"];
  get uNMatrix => currentProgram.uniforms["uNMatrix"];
  get uColorMapSampler => currentProgram.uniforms["uColorMapSampler"];
  get uSpecularMapSampler => currentProgram.uniforms["uSpecularMapSampler"];
  get uUseColorMap => currentProgram.uniforms["uUseColorMap"];
  get uUseSpecularMap => currentProgram.uniforms["uUseSpecularMap"];
  get uUseLighting => currentProgram.uniforms["uUseLighting"];
  get uAmbientColor => currentProgram.uniforms["uAmbientColor"];
  get uPointLightingLocation =>
      currentProgram.uniforms["uPointLightingLocation"];
  get uPointLightingSpecularColor =>
      currentProgram.uniforms["uPointLightingSpecularColor"];
  get uPointLightingDiffuseColor =>
      currentProgram.uniforms["uPointLightingDiffuseColor"];

  void drawScene(num viewWidth, num viewHeight, num aspect) {
    if (!isLoaded) return;
    // Setup the viewport, pulling information from the element.
    gl.viewport(0, 0, viewWidth, viewHeight);

    // Clear!
    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);

    gl.enable(WebGL.DEPTH_TEST);
    gl.disable(WebGL.BLEND);

    pMatrix = Matrix4.perspective(45.0, aspect, 0.1, 100.0);

    gl.uniform1i(uUseColorMap, _colorMap.checked ? 1 : 0);
    gl.uniform1i(uUseSpecularMap, _specularMap.checked ? 1 : 0);

    gl.uniform1i(uUseLighting, _lighting.checked ? 1 : 0);
    if (_lighting.checked) {
      gl.uniform3f(uAmbientColor, double.parse(_aR.value),
          double.parse(_aG.value), double.parse(_aB.value));

      gl.uniform3f(uPointLightingLocation, double.parse(_lpX.value),
          double.parse(_lpY.value), double.parse(_lpZ.value));

      gl.uniform3f(uPointLightingSpecularColor, double.parse(_sR.value),
          double.parse(_sG.value), double.parse(_sB.value));

      gl.uniform3f(uPointLightingDiffuseColor, double.parse(_dR.value),
          double.parse(_dG.value), double.parse(_dB.value));
    }

    mvPushMatrix();

    mvMatrix
      ..translate([0.0, 0.0, -40.0])
      ..rotate(radians(tilt), [1, 0, -1])
      ..rotateY(radians(sphereAngle));

    gl.activeTexture(WebGL.TEXTURE0);
    if (_texture.value == "earth") {
      gl.bindTexture(WebGL.TEXTURE_2D, earthTexture);
    } else if (_texture.value == "moon") {
      gl.bindTexture(WebGL.TEXTURE_2D, moonTexture);
    }
    gl.uniform1i(uColorMapSampler, 0);

    gl.activeTexture(WebGL.TEXTURE1);
    gl.bindTexture(WebGL.TEXTURE_2D, earthSpecularMapTexture);
    gl.uniform1i(uSpecularMapSampler, 1);

    sphere.draw(
        vertex: aVertexPosition,
        normal: aVertexNormal,
        coord: aTextureCoord,
        setUniforms: setMatrixUniforms);
    mvPopMatrix();
  }

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
      sphereAngle += 0.05 * elapsed;
    }
    lastTime = now;
  }

  void handleKeys() {
    handleDirection(
        up: () => tilt -= 1.0,
        down: () => tilt += 1.0,
        left: () => sphereAngle -= 1.0,
        right: () => sphereAngle += 1.0);
  }

  // Lighting enabled / Ambient color
  InputElement _lighting, _aR, _aG, _aB;

  // Light position
  InputElement _lpX, _lpY, _lpZ;

  // Difuse color
  InputElement _dR, _dG, _dB;

  // Specular color
  InputElement _sR, _sG, _sB;

  // Assorted options
  InputElement _colorMap, _specularMap;
  SelectElement _texture;

  void initHtml(DivElement hook) {
    hook.setInnerHtml(
        """
    <input type="checkbox" id="color-map" checked /> Use color map<br/>
    <input type="checkbox" id="specular-map" checked /> Use specular map<br/>
    <input type="checkbox" id="lighting" checked /> Use lighting<br/>

    Texture:
    <select id="texture">
        <option selected value="earth">Earth</option>
        <option value="moon">Moon</option>
    </select>
    <h2>Point light:</h2>

    <table style="border: 0; padding: 10px;">
        <tr>
            <td><b>Location:</b>
            <td>X: <input type="text" id="lightPositionX" value="-10.0" />
            <td>Y: <input type="text" id="lightPositionY" value="4.0" />
            <td>Z: <input type="text" id="lightPositionZ" value="-20.0" />
        </tr>
        <tr>
            <td><b>Specular colour:</b>
            <td>R: <input type="text" id="specularR" value="5.0" />
            <td>G: <input type="text" id="specularG" value="5.0" />
            <td>B: <input type="text" id="specularB" value="5.0" />
        </tr>
        <tr>
            <td><b>Diffuse colour:</b>
            <td>R: <input type="text" id="diffuseR" value="0.8" />
            <td>G: <input type="text" id="diffuseG" value="0.8" />
            <td>B: <input type="text" id="diffuseB" value="0.8" />
        </tr>
    </table>

    <h2>Ambient light:</h2>

    <table style="border: 0; padding: 10px;">
        <tr>
            <td><b>Colour:</b>
            <td>R: <input type="text" id="ambientR" value="0.4" />
            <td>G: <input type="text" id="ambientG" value="0.4" />
            <td>B: <input type="text" id="ambientB" value="0.4" />
        </tr>
    </table>

    Earth texture courtesy of <a href="http://www.esa.int/esaEO/SEMGSY2IU7E_index_0.html">the European Space Agency/Envisat</a>.<br/>
    Galvanized texture courtesy of <a href="http://www.arroway-textures.com/">Arroway Textures</a>.<br/>
    Moon texture courtesy of <a href="http://maps.jpl.nasa.gov/">the Jet Propulsion Laboratory</a>.
    """,
        treeSanitizer: new NullTreeSanitizer());

    // Re-look up our dom elements
    _lighting = querySelector("#lighting");
    _aR = querySelector("#ambientR");
    _aG = querySelector("#ambientG");
    _aB = querySelector("#ambientB");

    _lpX = querySelector("#lightPositionX");
    _lpY = querySelector("#lightPositionY");
    _lpZ = querySelector("#lightPositionZ");

    _dR = querySelector("#diffuseR");
    _dG = querySelector("#diffuseG");
    _dB = querySelector("#diffuseB");

    _sR = querySelector("#specularR");
    _sG = querySelector("#specularG");
    _sB = querySelector("#specularB");

    _colorMap = querySelector("#color-map");
    _specularMap = querySelector("#specular-map");
    _texture = querySelector("#texture");
  }
}
