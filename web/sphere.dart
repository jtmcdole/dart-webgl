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

class Sphere implements Renderable {
  final int lats;
  final int lons;
  final num radius;

  Buffer _positionBuffer;
  Buffer _normalBuffer;
  Buffer _textureCoordBuffer;
  Buffer _indexBuffer;
  int _indexBufferSize;

  Sphere({this.lats: 30, this.lons: 30, this.radius: 2}) {
    List<double> vertexPositions = new List();
    List<double> normals = new List();
    List<double> textureCoords = new List();
    List<int> indexData = new List();

    // Step 1: Generate normals, texture coordinates and vertex positions
    for (int lat = 0; lat <= lats; lat++) {
      var theta = lat * PI / lats;
      var sinTheta = sin(theta);
      var cosTheta = cos(theta);

      for (int lon = 0; lon <= lons; lon++) {
        var phi = lon * 2 * PI / lons;
        var sinPhi = sin(phi);
        var cosPhi = cos(phi);

        var x = cosPhi * sinTheta;
        var y = cosTheta;
        var z = sinPhi * sinTheta;
        var u = 1 - (lon / lons);
        var v = 1 - (lat / lats);

        normals.addAll([x, y, z]);
        textureCoords.addAll([u, v]);
        vertexPositions.addAll([radius * x, radius * y, radius * z]);
      }
    }

    // Step 2: Stich vertex positions together as a series of triangles.
    for (var lat = 0; lat < lats; lat++) {
      for (var lon = 0; lon < lons; lon++) {
        var first = (lat * (lons + 1)) + lon;
        var second = first + lons + 1;
        indexData
            .addAll([first, second, first + 1, second, second + 1, first + 1]);
      }
    }
    _indexBufferSize = indexData.length;

    _normalBuffer = gl.createBuffer();
    gl.bindBuffer(ARRAY_BUFFER, _normalBuffer);
    gl.bufferDataTyped(
        ARRAY_BUFFER, new Float32List.fromList(normals), STATIC_DRAW);

    _textureCoordBuffer = gl.createBuffer();
    gl.bindBuffer(ARRAY_BUFFER, _textureCoordBuffer);
    gl.bufferDataTyped(
        ARRAY_BUFFER, new Float32List.fromList(textureCoords), STATIC_DRAW);

    _positionBuffer = gl.createBuffer();
    gl.bindBuffer(ARRAY_BUFFER, _positionBuffer);
    gl.bufferDataTyped(
        ARRAY_BUFFER, new Float32List.fromList(vertexPositions), STATIC_DRAW);

    _indexBuffer = gl.createBuffer();
    gl.bindBuffer(ELEMENT_ARRAY_BUFFER, _indexBuffer);
    gl.bufferDataTyped(
        ELEMENT_ARRAY_BUFFER, new Uint16List.fromList(indexData), STATIC_DRAW);
  }

  void draw({int vertex, int normal, int coord, setUniforms()}) {
    if (vertex != null) {
      gl.bindBuffer(ARRAY_BUFFER, _positionBuffer);
      gl.vertexAttribPointer(vertex, 3, FLOAT, false, 0, 0);
    }

    if (normal != null) {
      gl.bindBuffer(ARRAY_BUFFER, _normalBuffer);
      gl.vertexAttribPointer(normal, 3, FLOAT, false, 0, 0);
    }

    if (coord != null) {
      gl.bindBuffer(ARRAY_BUFFER, _textureCoordBuffer);
      gl.vertexAttribPointer(coord, 2, FLOAT, false, 0, 0);
    }

    if (setUniforms != null) setUniforms();

    gl.bindBuffer(ELEMENT_ARRAY_BUFFER, _indexBuffer);
    gl.drawElements(TRIANGLES, _indexBufferSize, UNSIGNED_SHORT, 0);
  }
}
