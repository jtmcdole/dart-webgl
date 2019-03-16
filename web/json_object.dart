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

/// Load a JSON object that follows:
///     {
///       'vertexNormals': [],
///       'vertexTextureCoords': [],
///       'vertexPositions': [],
///       'indices': [],
///     }
///  Use [fromUrl] to load and return the object in the future!
///  If 'indicies' are absent - data is interpreted as a triangle strip.
class JsonObject implements Renderable {
  Buffer vertexNormalBuffer,
      textureCoordBuffer,
      vertexPositionBuffer,
      indexBuffer;
  int _itemSize;

  bool strip = false;

  JsonObject(String fromJson) {
    Map data = json.decode(fromJson);

    List<dynamic> numArray = data['vertexNormals'];
    if (numArray != null) {
      List<double> normals =
          new List<double>.from(numArray.map((index) => index.toDouble()));

      vertexNormalBuffer = gl.createBuffer();
      gl.bindBuffer(WebGL.ARRAY_BUFFER, vertexNormalBuffer);
      gl.bufferData(
        WebGL.ARRAY_BUFFER,
        new Float32List.fromList(normals),
        WebGL.STATIC_DRAW,
      );
    }

    numArray = data['vertexTextureCoords'];
    if (numArray != null) {
      List<double> coords =
          new List<double>.from(numArray.map((index) => index.toDouble()));

      textureCoordBuffer = gl.createBuffer();
      gl.bindBuffer(WebGL.ARRAY_BUFFER, textureCoordBuffer);
      gl.bufferData(
        WebGL.ARRAY_BUFFER,
        new Float32List.fromList(coords),
        WebGL.STATIC_DRAW,
      );
    }

    numArray = data['vertexPositions'];
    List<double> positions =
        new List<double>.from(numArray.map((index) => index.toDouble()));

    vertexPositionBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.ARRAY_BUFFER, vertexPositionBuffer);
    gl.bufferData(
      WebGL.ARRAY_BUFFER,
      new Float32List.fromList(positions),
      WebGL.STATIC_DRAW,
    );

    numArray = data['indices'];
    if (numArray != null) {
      List<int> indices =
          new List<int>.from(numArray.map((index) => (index as num).toInt()));
      indexBuffer = gl.createBuffer();
      gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, indexBuffer);
      gl.bufferData(
        WebGL.ELEMENT_ARRAY_BUFFER,
        new Uint16List.fromList(indices),
        WebGL.STATIC_DRAW,
      );
      _itemSize = indices.length;
    } else {
      _itemSize = positions.length ~/ 3;
    }
  }

  /// Return a future [JsonObject] by fetching the JSON data from [url].
  static Future<JsonObject> fromUrl(String url) {
    Completer<JsonObject> complete = new Completer<JsonObject>();
    HttpRequest.getString(url).then((json) {
      JsonObject obj = new JsonObject(json);
      print("json object from $url loaded as $obj");
      complete.complete(obj);
    });
    return complete.future;
  }

  void draw({int vertex, int normal, int coord, setUniforms()}) {
    if (vertex != null) {
      gl.bindBuffer(WebGL.ARRAY_BUFFER, vertexPositionBuffer);
      gl.vertexAttribPointer(vertex, 3, WebGL.FLOAT, false, 0, 0);
    }

    if (normal != null && vertexNormalBuffer != null) {
      gl.bindBuffer(WebGL.ARRAY_BUFFER, vertexNormalBuffer);
      gl.vertexAttribPointer(normal, 3, WebGL.FLOAT, false, 0, 0);
    }

    if (coord != null && textureCoordBuffer != null) {
      gl.bindBuffer(WebGL.ARRAY_BUFFER, textureCoordBuffer);
      gl.vertexAttribPointer(coord, 2, WebGL.FLOAT, false, 0, 0);
    }

    if (setUniforms != null) setUniforms();

    if (indexBuffer != null) {
      gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, indexBuffer);
      gl.drawElements(WebGL.TRIANGLES, _itemSize, WebGL.UNSIGNED_SHORT, 0);
    } else if (strip) {
      gl.drawArrays(WebGL.TRIANGLE_STRIP, 0, _itemSize);
    } else {
      gl.drawArrays(WebGL.TRIANGLES, 0, _itemSize);
    }
  }
}
