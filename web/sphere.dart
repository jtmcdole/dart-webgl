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
  final double radius;

  late Buffer _positionBuffer;
  late Buffer _normalBuffer;
  late Buffer _textureCoordBuffer;
  late Buffer _indexBuffer;
  int _indexBufferSize = 0;

  Sphere({this.lats = 30, this.lons = 30, this.radius = 2}) {
    final vertexPositions = <double>[];
    final normals = <double>[];
    final textureCoords = <double>[];
    final indexData = <int>[];

    // Step 1: Generate normals, texture coordinates and vertex positions
    for (var lat = 0; lat <= lats; lat++) {
      final theta = lat * pi / lats;
      final sinTheta = sin(theta);
      final cosTheta = cos(theta);

      for (var lon = 0; lon <= lons; lon++) {
        final phi = lon * 2 * pi / lons;
        final sinPhi = sin(phi);
        final cosPhi = cos(phi);

        final x = cosPhi * sinTheta;
        final y = cosTheta;
        final z = sinPhi * sinTheta;
        final u = 1 - (lon / lons);
        final v = 1 - (lat / lats);

        normals.addAll([x, y, z]);
        textureCoords.addAll([u, v]);
        vertexPositions.addAll([radius * x, radius * y, radius * z]);
      }
    }

    // Step 2: Stich vertex positions together as a series of triangles.
    for (var lat = 0; lat < lats; lat++) {
      for (var lon = 0; lon < lons; lon++) {
        final first = (lat * (lons + 1)) + lon;
        final second = first + lons + 1;
        indexData.addAll([first, second, first + 1, second, second + 1, first + 1]);
      }
    }
    _indexBufferSize = indexData.length;

    _normalBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.ARRAY_BUFFER, _normalBuffer);
    gl.bufferData(
      WebGL.ARRAY_BUFFER,
      Float32List.fromList(normals),
      WebGL.STATIC_DRAW,
    );

    _textureCoordBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.ARRAY_BUFFER, _textureCoordBuffer);
    gl.bufferData(
      WebGL.ARRAY_BUFFER,
      Float32List.fromList(textureCoords),
      WebGL.STATIC_DRAW,
    );

    _positionBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.ARRAY_BUFFER, _positionBuffer);
    gl.bufferData(
      WebGL.ARRAY_BUFFER,
      Float32List.fromList(vertexPositions),
      WebGL.STATIC_DRAW,
    );

    _indexBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, _indexBuffer);
    gl.bufferData(
      WebGL.ELEMENT_ARRAY_BUFFER,
      Uint16List.fromList(indexData),
      WebGL.STATIC_DRAW,
    );
  }

  @override
  void draw({int? vertex, int? normal, int? coord, Function()? setUniforms}) {
    if (vertex != null) {
      gl.bindBuffer(WebGL.ARRAY_BUFFER, _positionBuffer);
      gl.vertexAttribPointer(vertex, 3, WebGL.FLOAT, false, 0, 0);
    }

    if (normal != null) {
      gl.bindBuffer(WebGL.ARRAY_BUFFER, _normalBuffer);
      gl.vertexAttribPointer(normal, 3, WebGL.FLOAT, false, 0, 0);
    }

    if (coord != null) {
      gl.bindBuffer(WebGL.ARRAY_BUFFER, _textureCoordBuffer);
      gl.vertexAttribPointer(coord, 2, WebGL.FLOAT, false, 0, 0);
    }

    if (setUniforms != null) setUniforms();

    gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, _indexBuffer);
    gl.drawElements(WebGL.TRIANGLES, _indexBufferSize, WebGL.UNSIGNED_SHORT, 0);
  }
}
