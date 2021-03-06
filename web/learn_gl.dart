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
library learn_gl;

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:math';
import 'dart:typed_data';
import 'dart:web_gl';

part 'cube.dart';
part 'gl_program.dart';
part 'json_object.dart';
// All the lessons
part 'lesson1.dart';
part 'lesson10.dart';
part 'lesson11.dart';
part 'lesson12.dart';
part 'lesson13.dart';
part 'lesson14.dart';
part 'lesson15.dart';
part 'lesson16.dart';
part 'lesson2.dart';
part 'lesson3.dart';
part 'lesson4.dart';
part 'lesson5.dart';
part 'lesson6.dart';
part 'lesson7.dart';
part 'lesson8.dart';
part 'lesson9.dart';
// Math
part 'matrix4.dart';
part 'pyramid.dart';
part 'rectangle.dart';
// Some of our objects that we're going to support
part 'renderable.dart';
part 'sphere.dart';
part 'star.dart';

final canvas = querySelector('#lesson01-canvas') as CanvasElement;
late RenderingContext2 gl;
late Lesson lesson;

void main() {
  mvMatrix = Matrix4()..identity();
  // Nab the context we'll be drawing to.
  // gl = canvas.getContext3d();
  gl = canvas.getContext('webgl2') as RenderingContext2;

  // Allow some URL customization of the program.
  parseQueryString();

  trackFrameRate = urlParameters.containsKey('fps');
  if (!trackFrameRate) {
    querySelector('#fps')!.remove();
  }
  if (urlParameters.containsKey('width')) {
    final String width = urlParameters['width'];
    canvas.width = int.tryParse(width) ?? 500;
  }

  if (urlParameters.containsKey('height')) {
    final String height = urlParameters['height'];
    canvas.height = int.tryParse(height) ?? 500;
  }

  if (urlParameters.containsKey('overflow')) {
    document.body!.style.overflow = 'hidden';
  }

  var defaultLesson = 1;
  if (urlParameters.containsKey('lsn')) {
    defaultLesson = int.parse(urlParameters['lsn']);
  }

  final lessonSelect = querySelector('#lessonNumber') as SelectElement;
  for (var i = 1; i < 17; i++) {
    lessonSelect.children.add(OptionElement(
      data: 'Lesson $i',
      value: '$i',
      selected: defaultLesson == i,
    ));
  }
  lessonSelect.onChange.listen((event) {
    lesson = selectLesson(lessonSelect.selectedIndex! + 1)!..initHtml(lessonHook);
  });
  lesson = selectLesson(lessonSelect.selectedIndex! + 1)!..initHtml(lessonHook);

  // Set the fill color to black
  gl.clearColor(0, 0, 0, 1.0);

  // Hook into the window's onKeyDown and onKeyUp streams to track key states
  window.onKeyDown.listen((KeyboardEvent event) {
    currentlyPressedKeys.add(event.keyCode);
  });

  window.onKeyUp.listen((event) {
    currentlyPressedKeys.remove(event.keyCode);
  });

  // Start off the infinite animation loop
  tick(0);
}

/// This is the infinite animation loop; we request that the web browser
/// call us back every time its ready for a  frame to be rendered. The [time]
/// parameter is an increasing value based on when the animation loop started.
void tick(time) {
  window.animationFrame.then(tick);
  if (trackFrameRate) frameCount(time);
  lesson.handleKeys();
  lesson.animate(time);
  lesson.drawScene(canvas.width!, canvas.height!, canvas.width! / canvas.height!);
}

/// The global key-state map.
Set<int> currentlyPressedKeys = <int>{};

/// Test if the given [KeyCode] is active.
bool isActive(int code) => currentlyPressedKeys.contains(code);

/// Test if any of the given [KeyCode]s are active, returning true.
bool anyActive(List<int> codes) {
  return codes.firstWhere((code) => currentlyPressedKeys.contains(code), orElse: () => -1) != -1;
}

/// Parse and store the URL parameters for start up.
void parseQueryString() {
  var search = window.location.search!;
  if (search.startsWith('?')) {
    search = search.substring(1);
  }
  final params = search.split('&');
  for (var param in params) {
    final pair = param.split('=');
    if (pair.length == 1) {
      urlParameters[pair[0]] = '';
    } else {
      urlParameters[pair[0]] = pair[1];
    }
  }
}

Map urlParameters = {};

/// Perspective matrix
late Matrix4 pMatrix;

/// Model-View matrix.
late Matrix4 mvMatrix;

List<Matrix4> mvStack = <Matrix4>[];

/// Add a copy of the current Model-View matrix to the the stack for future
/// restoration.
void mvPushMatrix() => mvStack.add(Matrix4.fromMatrix(mvMatrix));

/// Pop the last matrix off the stack and set the Model View matrix.
void mvPopMatrix() => mvMatrix = mvStack.removeLast();

/// Handle common keys through callbacks, making lessons a little easier to code
void handleDirection({Function()? up, Function()? down, Function()? left, Function()? right}) {
  if (left != null && anyActive([KeyCode.A, KeyCode.LEFT])) {
    left();
  }
  if (right != null && anyActive([KeyCode.D, KeyCode.RIGHT])) {
    right();
  }
  if (down != null && anyActive([KeyCode.S, KeyCode.DOWN])) {
    down();
  }
  if (up != null && anyActive([KeyCode.W, KeyCode.UP])) {
    up();
  }
}

/// FPS meter - activated when the url parameter "fps" is included.
const double ALPHA_DECAY = 0.1;
const double INVERSE_ALPHA_DECAY = 1 - ALPHA_DECAY;
const SAMPLE_RATE_MS = 500;
const SAMPLE_FACTOR = 1000 ~/ SAMPLE_RATE_MS;
int frames = 0;
double lastSample = 0;
double averageFps = 1;
DivElement fps = querySelector('#fps') as DivElement;

void frameCount(double now) {
  frames++;
  if ((now - lastSample) < SAMPLE_RATE_MS) return;
  averageFps = averageFps * ALPHA_DECAY + frames * INVERSE_ALPHA_DECAY * SAMPLE_FACTOR;
  fps.text = averageFps.toStringAsFixed(2);
  frames = 0;
  lastSample = now;
}

/// The base for all Learn WebGL lessons.
abstract class Lesson {
  /// Render the scene to the [viewWidth], [viewHeight], and [aspect] ratio.
  void drawScene(int viewWidth, int viewHeight, double aspect);

  /// Animate the scene any way you like. [now] is provided as a clock reference
  /// since the scene rendering started.
  void animate(double now) {}

  /// Handle any keyboard events.
  void handleKeys() {}

  /// Fill in any lesson related instructions and input elements.
  /// This is provided by default.
  void initHtml(DivElement hook) {
    hook.innerHtml = "If you see this, don't worry, the lesson doesn't have "
        'any parameters for you to change! Generally up/down/left/right or '
        'WASD work.';
  }

  /// Added for your convenience to track time between [animate] callbacks.
  double lastTime = 0;
}

/// Load the given image at [url] and call [handle] to execute some GL code.
/// Return a [Future] to asynchronously notify when the texture is complete.
Future<Texture> loadTexture(String url, Function(Texture tex, ImageElement ele) handle) {
  final completer = Completer<Texture>();
  final texture = gl.createTexture();
  final element = ImageElement();
  element.onLoad.listen((e) {
    handle(texture, element);
    completer.complete(texture);
  });
  element.src = url;
  return completer.future;
}

/// This is a common handler for [loadTexture]. It will be explained in future
/// lessons that require textures.
void handleMipMapTexture(Texture texture, ImageElement image) {
  gl.pixelStorei(WebGL.UNPACK_FLIP_Y_WEBGL, 1);
  gl.bindTexture(WebGL.TEXTURE_2D, texture);
  gl.texImage2D(
    WebGL.TEXTURE_2D,
    0,
    WebGL.RGBA,
    WebGL.RGBA,
    WebGL.UNSIGNED_BYTE,
    image,
  );
  gl.texParameteri(
    WebGL.TEXTURE_2D,
    WebGL.TEXTURE_MAG_FILTER,
    WebGL.LINEAR,
  );
  gl.texParameteri(
    WebGL.TEXTURE_2D,
    WebGL.TEXTURE_MIN_FILTER,
    WebGL.LINEAR_MIPMAP_NEAREST,
  );
  gl.generateMipmap(WebGL.TEXTURE_2D);
  gl.bindTexture(WebGL.TEXTURE_2D, null);
}

DivElement lessonHook = querySelector('#lesson_html') as DivElement;
bool trackFrameRate = false;

Lesson? selectLesson(int number) {
  switch (number) {
    case 1:
      return Lesson1();
    case 2:
      return Lesson2();
    case 3:
      return Lesson3();
    case 4:
      return Lesson4();
    case 5:
      return Lesson5();
    case 6:
      return Lesson6();
    case 7:
      return Lesson7();
    case 8:
      return Lesson8();
    case 9:
      return Lesson9();
    case 10:
      return Lesson10();
    case 11:
      return Lesson11();
    case 12:
      return Lesson12();
    case 13:
      return Lesson13();
    case 14:
      return Lesson14();
    case 15:
      return Lesson15();
    case 16:
      return Lesson16();
  }
  return null;
}

/// Work around for setInnerHtml()
class NullTreeSanitizer implements NodeTreeSanitizer {
  static NullTreeSanitizer? instance;
  factory NullTreeSanitizer() {
    instance ??= NullTreeSanitizer._();
    return instance!;
  }

  NullTreeSanitizer._();
  @override
  void sanitizeTree(Node node) {}
}
