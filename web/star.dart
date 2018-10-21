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
 * Note; not happy about this, it just a texturized rectangle that's conflated
 * with particles. Needs clean up.
 */
class Star implements Renderable {
  static Random rand = new Random(42);
  static bool loaded = false;
  static int starCount = 0;
  final int id = starCount++;

  num dist;
  num rotationSpeed;
  num angle = 0.0;

  /// Normal color
  num r, g, b;

  /// Twinkle color
  num rT, gT, bT;

  Star(this.dist, this.rotationSpeed) {
    randomizeColors();
    starVertexPositionBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.ARRAY_BUFFER, starVertexPositionBuffer);
    var vertices = [
      -1.0,
      -1.0,
      0.0,
      1.0,
      -1.0,
      0.0,
      -1.0,
      1.0,
      0.0,
      1.0,
      1.0,
      0.0
    ];
    gl.bufferData(
        WebGL.ARRAY_BUFFER, new Float32List.fromList(vertices), WebGL.STATIC_DRAW);

    starVertexTextureCoordBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.ARRAY_BUFFER, starVertexTextureCoordBuffer);
    var textureCoords = [0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0];
    gl.bufferData(
        WebGL.ARRAY_BUFFER, new Float32List.fromList(textureCoords), WebGL.STATIC_DRAW);
  }

  void draw(
      {int vertex,
      int normal,
      int coord,
      UniformLocation color,
      bool twinkle: false,
      num tilt,
      num spin,
      setUniforms()}) {
    mvPushMatrix();

    // Move to the star's position
    mvMatrix
      ..rotateY(radians(angle))
      ..translate([dist, 0.0, 0.0]);

    // Rotate back so that the star is facing the viewer
    mvMatrix
      ..rotateY(radians(-angle))
      ..rotateX(radians(-tilt));

    if (twinkle) {
      // Draw a non-rotating star in the alternate "twinkling" color
      gl.uniform3f(color, rT, gT, bT);
      drawStar(vertex, normal, coord, setUniforms);
    }

    mvMatrix.rotateZ(radians(spin));

    // Draw the star in its main color
    gl.uniform3f(color, r, g, b);
    drawStar(vertex, normal, coord, setUniforms);

    mvPopMatrix();
  }

  static const num effectiveFPMS = 60 / 1000;
  void animate(num time) {
    angle += rotationSpeed * effectiveFPMS * time;

    // Decrease the distance, resetting the star to the outside of
    // the spiral if it's at the center.
    dist -= 0.01 * effectiveFPMS * time;
    if (dist < 0.0) {
      dist += 5.0;
      randomizeColors();
    }
  }

  void randomizeColors() {
    r = rand.nextDouble();
    g = rand.nextDouble();
    b = rand.nextDouble();
    rT = rand.nextDouble();
    gT = rand.nextDouble();
    bT = rand.nextDouble();
  }

  Buffer starVertexPositionBuffer;
  Buffer starVertexTextureCoordBuffer;

  void drawStar(int vertex, int normal, int coord, setUniforms()) {
    gl.bindBuffer(WebGL.ARRAY_BUFFER, starVertexTextureCoordBuffer);
    gl.vertexAttribPointer(coord, 2, WebGL.FLOAT, false, 0, 0);

    gl.bindBuffer(WebGL.ARRAY_BUFFER, starVertexPositionBuffer);
    gl.vertexAttribPointer(vertex, 3, WebGL.FLOAT, false, 0, 0);

    setUniforms();
    gl.drawArrays(WebGL.TRIANGLE_STRIP, 0, 4);
  }
}
